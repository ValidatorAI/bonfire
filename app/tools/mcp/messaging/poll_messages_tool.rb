module Mcp
  module Messaging
    class PollMessagesTool < Mcp::BaseTool
      description "Long-poll for new messages in subscribed rooms"

      schema(
        properties: {
          since: { type: "string", description: "ISO8601 timestamp to poll from" },
          room_ids: { type: "array", items: { type: "integer" }, description: "Specific room IDs to poll (defaults to all joined rooms)" },
          timeout_seconds: { type: "integer", description: "Poll timeout in seconds (server-configured default/max)" }
        },
        required: %w[since]
      )

      MAX_MESSAGES = 50

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          since = Time.parse(params[:since])
          room_ids = params[:room_ids]
          timeout_seconds = normalize_timeout(params[:timeout_seconds])

          rooms = room_ids ? agent.rooms.where(id: room_ids) : agent.rooms
          return error_response("No rooms to poll", code: "validation_error") if rooms.empty?

          start_time = Time.current
          messages = []

          # Long-poll loop
          loop do
            messages = fetch_new_messages(agent, rooms, since)
            break if messages.any?
            break if Time.current - start_time > timeout_seconds

            sleep poll_interval
          end

          # Update agent presence
          agent.heartbeat!

          success_response({
            messages: messages.map { |m| serialize_message(m) },
            polled_until: Time.current.iso8601,
            has_more: messages.size >= MAX_MESSAGES
          })
        end

        private

        def fetch_new_messages(agent, rooms, since)
          Message.where(room_id: rooms.pluck(:id))
                 .where("created_at > ?", since)
                 .where.not(creator_type: "Agent", creator_id: agent.id)
                 .order(:created_at)
                 .limit(MAX_MESSAGES)
        end

        def normalize_timeout(requested_timeout)
          config = Rails.application.config.mcp
          default_timeout = config.poll_default_timeout_seconds.to_i
          max_timeout = [ config.poll_max_timeout_seconds.to_i, 1 ].max
          timeout = requested_timeout.present? ? requested_timeout.to_i : default_timeout
          timeout.clamp(1, max_timeout)
        end

        def poll_interval
          interval_seconds = Rails.application.config.mcp.poll_interval_seconds.to_f
          [ interval_seconds, 0.05 ].max
        end

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
