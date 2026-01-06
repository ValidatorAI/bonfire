module Mcp
  module Workflow
    class MacroStartSessionTool < Mcp::BaseTool
      description "Macro tool to start a complete agent session: register/reconnect, join project room, and optionally reserve files"

      schema(
        properties: {
          project_path: { type: "string", description: "Filesystem path to the project" },
          program: { type: "string", description: "Agent program (Claude Code, Codex CLI, etc.)" },
          model: { type: "string", description: "LLM model identifier" },
          name: { type: "string", description: "Existing agent name to reconnect (omit for auto-generated name)" },
          task_description: { type: "string", description: "Current work context" },
          reserve_patterns: { type: "array", items: { type: "string" }, description: "Optional file patterns to reserve immediately" }
        },
        required: %w[project_path program model]
      )

      class << self
        def call(params)
          project_path = params[:project_path]
          program = params[:program]
          model = params[:model]
          task_description = params[:task_description]
          name = params[:name]  # Optional - for reconnecting to existing identity
          reserve_patterns = params[:reserve_patterns]

          # Step 1: Find or create project
          project = Project.find_or_create_for_path(project_path)
          project.ensure_project_room!

          # Step 2: Find existing agent by name, or create new one with generated name
          if name.present?
            # Reconnect to existing agent
            agent = project.agents.find_by(name: name)
            return error_response("Agent '#{name}' not found in this project", code: "not_found") unless agent
            is_new = false
          else
            # New agent - generate unique name
            generated_name = Agent::NameGenerator.generate(project)
            agent = project.agents.build(name: generated_name)
            is_new = true
          end

          agent.assign_attributes(
            program: program,
            model: model,
            task_description: task_description,
            status: :online,
            last_active_at: Time.current
          )
          agent.save!
          ensure_agent_token(agent)

          session_id = session_identifier(params)
          agent.update!(mcp_session_id: session_id)

          # Step 3: Auto-join project room (posts join message only for new agents)
          if is_new
            project.project_room.auto_join_agent(agent)
          else
            agent.heartbeat!
          end

          # Step 4: Reserve files if requested
          reservation = nil
          if reserve_patterns.present?
            # Check for conflicts first
            conflicts = project.file_reservations.active.exclusive
                              .select { |r| r.conflicts_with?(reserve_patterns) }

            if conflicts.empty?
              reservation = project.file_reservations.create!(
                agent: agent,
                patterns: reserve_patterns,
                exclusive: true,
                reason: "Initial session reservation",
                expires_at: 1.hour.from_now
              )
            end
          end

          # Step 5: Fetch recent messages from project room
          recent_messages = project.project_room.messages
                                   .order(created_at: :desc)
                                   .limit(20)
                                   .reverse

          success_response({
            agent: {
              id: agent.id,
              name: agent.name
            },
            credentials: {
              api_token: agent.api_token,
              session_id: session_id
            },
            project: {
              id: project.id,
              slug: project.slug,
              path: project.path
            },
            room: {
              id: project.project_room.id,
              name: project.project_room.name
            },
            reservation: reservation ? {
              id: reservation.id,
              patterns: reservation.patterns,
              expires_at: reservation.expires_at.iso8601
            } : nil,
            recent_messages: recent_messages.map do |m|
              {
                id: m.id,
                creator_type: m.creator_type,
                creator_name: m.creator&.name || "Unknown",
                body: m.plain_text_body,
                system: m.system?,
                created_at: m.created_at.iso8601
              }
            end,
            other_agents: project.agents.where.not(id: agent.id).active.map do |a|
              {
                id: a.id,
                name: a.name,
                program: a.program,
                status: a.status,
                task_description: a.task_description
              }
            end,
            reconnected: !is_new
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end

        def session_identifier(params)
          params.dig(:server_context, :mcp_session_id).presence || SecureRandom.uuid
        end

        def ensure_agent_token(agent)
          agent.regenerate_api_token! if agent.api_token.blank?
        end
      end
    end
  end
end
