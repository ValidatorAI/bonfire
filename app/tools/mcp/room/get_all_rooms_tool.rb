module Mcp
  module Room
    class GetAllRoomsTool < Mcp::BaseTool
      description "List all rooms across the instance, including project and non-project rooms"

      schema(
        properties: {
          include_archived: { type: "boolean", description: "Include archived rooms" },
          type: { type: "string", enum: %w[all project task open closed direct meta], description: "Filter by room type" },
          project_id: { type: "integer", description: "Optional project ID filter" },
          projectless_only: { type: "boolean", description: "Only return rooms with no project association" }
        },
        required: []
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          include_archived = params[:include_archived] == true
          type_filter = params[:type] || "all"
          project_id = params[:project_id]
          projectless_only = params[:projectless_only] == true

          rooms = ::Room.includes(:project, :memberships)
          rooms = rooms.active unless include_archived
          rooms = rooms.where(project_id: project_id) if project_id.present?
          rooms = rooms.where(project_id: nil) if projectless_only

          rooms = filter_by_type(rooms, type_filter)

          success_response({
            rooms: rooms.order(updated_at: :desc).map do |room|
              {
                id: room.id,
                name: room.name,
                type: room.type,
                description: room.description,
                archived: room.archived_at.present?,
                member_count: room.memberships.size,
                project: room.project ? {
                  id: room.project.id,
                  slug: room.project.slug,
                  path: room.project.path
                } : nil,
                created_at: room.created_at.iso8601,
                updated_at: room.updated_at.iso8601
              }
            end,
            total: rooms.count
          })
        end

        private

        def filter_by_type(rooms, type_filter)
          case type_filter
          when "project"
            rooms.projects
          when "task"
            rooms.tasks
          when "open"
            rooms.opens
          when "closed"
            rooms.closeds
          when "direct"
            rooms.directs
          when "meta"
            rooms.where(type: "Rooms::Meta")
          else
            rooms
          end
        end
      end
    end
  end
end