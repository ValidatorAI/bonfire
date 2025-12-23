module Mcp
  module Room
    class JoinRoomTool < Mcp::BaseTool
      description "Join a room to participate in conversations"

      schema(
        properties: {
          room_id: { type: "integer", description: "ID of the room to join" }
        },
        required: %w[room_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room = agent.project.rooms.find_by(id: params[:room_id])
          return error_response("Room not found", code: "not_found") unless room
          return error_response("Room is archived", code: "forbidden") if room.archived_at.present?

          if agent.memberships.exists?(room_id: room.id)
            return success_response({
              room_id: room.id,
              already_member: true,
              message: "Already a member of this room"
            })
          end

          room.memberships.grant_to(agent)
          SystemMessage.agent_joined(room: room, agent: agent)

          success_response({
            room_id: room.id,
            room_name: room.name,
            room_type: room.type,
            joined: true
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
