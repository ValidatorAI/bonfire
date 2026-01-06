module Mcp
  module Messaging
    class SearchMessagesTool < Mcp::BaseTool
      description "Search messages using full-text search. Uses SQLite FTS5 with Porter stemming for fuzzy matching."

      schema(
        properties: {
          query: {
            type: "string",
            description: "Search query (supports word matching with Porter stemming)"
          },
          room_ids: {
            type: "array",
            items: { type: "integer" },
            description: "Optional: limit search to specific room IDs (must be member)"
          },
          limit: {
            type: "integer",
            description: "Max results to return (default 50, max 100)"
          }
        },
        required: %w[query]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          query = sanitize_query(params[:query])
          return error_response("Query too short", code: "validation_error") if query.blank?

          limit = [[params[:limit] || 50, 100].min, 1].max

          # Get searchable messages (rooms agent is member of)
          messages = agent.reachable_messages.search(query)

          # Filter to specific rooms if requested
          if params[:room_ids].present?
            allowed_room_ids = agent.rooms.where(id: params[:room_ids]).pluck(:id)
            messages = messages.where(room_id: allowed_room_ids)
          end

          messages = messages.includes(:creator, :room).last(limit)

          success_response({
            query: query,
            count: messages.size,
            messages: messages.map { |m| serialize_message(m) }
          })
        end

        private

        def sanitize_query(query)
          query.to_s.gsub(/[^[:word:]]/, " ").squish
        end

        def serialize_message(m)
          {
            id: m.id,
            room_id: m.room_id,
            room_name: m.room&.name,
            creator: {
              type: m.creator_type,
              id: m.creator_id,
              name: m.creator&.name || "Unknown"
            },
            body: m.plain_text_body,
            created_at: m.created_at.iso8601
          }
        end
      end
    end
  end
end
