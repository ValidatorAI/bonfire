module Mcp
  module Messaging
    class MarkRoomReadTool < Mcp::BaseTool
      description "Mark a room as read up to a specific timestamp"

      schema(
        properties: {
          room_id: { type: "integer", description: "Room ID to mark as read" },
          read_at: { type: "string", description: "ISO8601 timestamp to mark as read up to (defaults to now)" }
        },
        required: %w[room_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room_id = params[:room_id]
          read_at = params[:read_at] ? Time.parse(params[:read_at]) : Time.current

          membership = agent.memberships.find_by(room_id: room_id)
          return error_response("Not a member of this room", code: "forbidden") unless membership

          membership.update!(last_read_at: read_at)

          success_response({
            room_id: room_id,
            last_read_at: membership.last_read_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
