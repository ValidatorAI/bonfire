module Mcp
  module Room
    class LeaveRoomTool < Mcp::BaseTool
      description "Leave a room"

      schema(
        properties: {
          room_id: { type: "integer", description: "ID of the room to leave" }
        },
        required: %w[room_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room = agent.project.rooms.find_by(id: params[:room_id])
          return error_response("Room not found", code: "not_found") unless room

          membership = agent.memberships.find_by(room_id: room.id)
          unless membership
            return success_response({
              room_id: room.id,
              already_left: true,
              message: "Not a member of this room"
            })
          end

          membership.destroy!
          SystemMessage.agent_left(room: room, agent: agent)

          success_response({
            room_id: room.id,
            room_name: room.name,
            left: true
          })
        end
      end
    end
  end
end
