module Mcp
  module Messaging
    class FetchMessagesTool < Mcp::BaseTool
      description "Fetch messages from a room"

      schema(
        properties: {
          room_id: { type: "integer", description: "Room ID to fetch messages from" },
          limit: { type: "integer", description: "Maximum number of messages to return (default 50, max 100)" },
          before_id: { type: "integer", description: "Fetch messages before this message ID (for pagination)" },
          since: { type: "string", description: "Fetch messages since this ISO8601 timestamp" }
        },
        required: %w[room_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room_id = params[:room_id]
          limit = [ params[:limit] || 50, 100 ].min
          before_id = params[:before_id]
          since = params[:since]

          membership = agent.memberships.find_by(room_id: room_id)
          return error_response("Not a member of this room", code: "forbidden") unless membership

          messages = membership.room.messages.order(created_at: :desc)
          messages = messages.where("id < ?", before_id) if before_id
          messages = messages.where("created_at >= ?", Time.parse(since)) if since
          messages = messages.limit(limit)

          success_response({
            room_id: room_id,
            messages: messages.reverse.map { |m| serialize_message(m) },
            has_more: messages.count == limit
          })
        end

        private

        def serialize_message(m)
          {
            id: m.id,
            room_id: m.room_id,
            creator: {
              type: m.creator_type,
              id: m.creator_id,
              name: m.creator&.name || "Unknown"
            },
            body: m.plain_text_body,
            system: m.system?,
            system_type: m.system_type,
            created_at: m.created_at.iso8601
          }
        end
      end
    end
  end
end
