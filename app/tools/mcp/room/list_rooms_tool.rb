module Mcp
  module Room
    class ListRoomsTool < Mcp::BaseTool
      description "List rooms available to the agent"

      schema(
        properties: {
          type: { type: "string", enum: %w[project task all], description: "Filter by room type" },
          include_archived: { type: "boolean", description: "Include archived rooms" },
          only_joined: { type: "boolean", description: "Only show rooms the agent has joined" }
        },
        required: []
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          type_filter = params[:type] || "all"
          include_archived = params[:include_archived] == true
          only_joined = params[:only_joined] == true

          rooms = agent.project.rooms
          rooms = rooms.active unless include_archived

          case type_filter
          when "project"
            rooms = rooms.projects
          when "task"
            rooms = rooms.tasks
          end

          if only_joined
            rooms = rooms.where(id: agent.rooms.pluck(:id))
          end

          joined_room_ids = agent.rooms.pluck(:id)

          success_response({
            rooms: rooms.map do |r|
              {
                id: r.id,
                name: r.name,
                type: r.type,
                description: r.description,
                joined: joined_room_ids.include?(r.id),
                archived: r.archived_at.present?,
                member_count: r.memberships.count,
                created_at: r.created_at.iso8601
              }
            end,
            total: rooms.count
          })
        end
      end
    end
  end
end
