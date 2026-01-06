module Mcp
  module Identity
    class RegisterAgentTool < Mcp::BaseTool
      description "Register or reconnect an agent identity for a project"

      schema(
        properties: {
          project_path: { type: "string", description: "Filesystem path to the project" },
          program: { type: "string", description: "Agent program (Claude Code, Codex CLI, etc.)" },
          model: { type: "string", description: "LLM model identifier" },
          task_description: { type: "string", description: "Current work context" },
          name: { type: "string", description: "Agent name (required for identification)" }
        },
        required: %w[project_path program model name]
      )

      class << self
        def call(params)
          project_path = params[:project_path]
          program = params[:program]
          model = params[:model]
          task_description = params[:task_description]
          name = params[:name]

          project = Project.find_or_create_for_path(project_path)
          project.ensure_project_room!

          # Find existing agent by name or create new one
          agent = project.agents.find_or_initialize_by(name: name)
          is_new = agent.new_record?

          agent.assign_attributes(
            program: program,
            model: model,
            task_description: task_description,
            status: :online,
            last_active_at: Time.current
          )
          agent.save!
          ensure_agent_token(agent)

          session_id = params.dig(:server_context, :mcp_session_id).presence || SecureRandom.uuid
          agent.update!(mcp_session_id: session_id)

          # Auto-join project room (posts join message only for new agents)
          if is_new
            project.project_room.auto_join_agent(agent)
          else
            # Just update presence for returning agents
            agent.heartbeat!
          end

          success_response({
            agent_id: agent.id,
            agent_name: agent.name,
            project_slug: project.slug,
            room_id: project.project_room.id,
            credentials: {
              api_token: agent.api_token,
              session_id: session_id
            },
            reconnected: !is_new
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end

        def ensure_agent_token(agent)
          agent.regenerate_api_token! if agent.api_token.blank?
        end
      end
    end
  end
end
