module Mcp
  module Room
    class GetRoomMembersTool < Mcp::BaseTool
      description "Get all members of a room"

      schema(
        properties: {
          room_id: { type: "integer", description: "ID of the room" }
        },
        required: %w[room_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room = agent.project.rooms.find_by(id: params[:room_id])
          return error_response("Room not found", code: "not_found") unless room

          users = room.users.map do |u|
            {
              type: "user",
              id: u.id,
              name: u.name,
              role: u.role
            }
          end

          agents = room.agents.map do |a|
            {
              type: "agent",
              id: a.id,
              name: a.name,
              program: a.program,
              model: a.model,
              status: a.status,
              task_description: a.task_description
            }
          end

          success_response({
            room_id: room.id,
            room_name: room.name,
            users: users,
            agents: agents,
            total_users: users.count,
            total_agents: agents.count
          })
        end
      end
    end
  end
end
