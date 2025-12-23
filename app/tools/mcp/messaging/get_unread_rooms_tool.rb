module Mcp
  module Messaging
    class GetUnreadRoomsTool < Mcp::BaseTool
      description "Get rooms with unread messages"

      schema(properties: {}, required: [])

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          unread_rooms = agent.memberships.includes(:room).map do |membership|
            room = membership.room
            last_read_at = membership.last_read_at || agent.created_at

            unread_count = room.messages
                              .where("created_at > ?", last_read_at)
                              .where.not(creator_type: "Agent", creator_id: agent.id)
                              .count

            next if unread_count.zero?

            {
              room_id: room.id,
              room_name: room.name,
              room_type: room.type,
              unread_count: unread_count,
              last_read_at: last_read_at.iso8601
            }
          end.compact

          success_response({
            rooms: unread_rooms,
            total_unread_rooms: unread_rooms.count
          })
        end
      end
    end
  end
end
