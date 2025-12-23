module Mcp
  module Room
    class CreateTaskRoomTool < Mcp::BaseTool
      description "Create a new task-specific room for focused collaboration"

      schema(
        properties: {
          name: { type: "string", description: "Name for the task room" },
          description: { type: "string", description: "Description of the task" },
          invite_agents: { type: "array", items: { type: "integer" }, description: "Agent IDs to invite" }
        },
        required: %w[name]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room = Rooms::Task.create!(
            project: agent.project,
            name: params[:name],
            description: params[:description],
            creator: agent
          )

          # Auto-join the creating agent
          room.memberships.grant_to(agent)

          # Invite additional agents if specified
          if params[:invite_agents].present?
            agents_to_invite = agent.project.agents.where(id: params[:invite_agents])
            room.memberships.grant_to(agents_to_invite)
          end

          success_response({
            room_id: room.id,
            room_name: room.name,
            room_type: room.type,
            description: room.description,
            member_count: room.memberships.count,
            created_at: room.created_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
