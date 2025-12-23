module Mcp
  module Messaging
    class SendMessageTool < Mcp::BaseTool
      description "Send a message to a room"

      schema(
        properties: {
          room_id: { type: "integer", description: "Room ID" },
          body: { type: "string", description: "Message body (markdown supported)" },
          client_message_id: { type: "string", description: "Optional client-side deduplication ID" }
        },
        required: %w[room_id body]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room_id = params[:room_id]
          body = params[:body]
          client_message_id = params[:client_message_id]

          membership = agent.memberships.find_by(room_id: room_id)
          return error_response("Not a member of this room", code: "forbidden") unless membership

          message = membership.room.messages.create!(
            creator: agent,
            body: body,
            client_message_id: client_message_id || SecureRandom.uuid
          )
          message.broadcast_create

          success_response({
            id: message.id,
            room_id: room_id,
            body: message.plain_text_body,
            created_at: message.created_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
