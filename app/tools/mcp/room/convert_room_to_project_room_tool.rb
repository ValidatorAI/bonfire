module Mcp
  module Room
    class ConvertRoomToProjectRoomTool < Mcp::BaseTool
      description "Convert a normal room into a project room"

      schema(
        properties: {
          room_id: { type: "integer", description: "Room ID to convert" },
          project_id: { type: "integer", description: "Target project ID (optional if project_path is provided or room already has project)" },
          project_path: { type: "string", description: "Target project path (optional alternative to project_id)" }
        },
        required: %w[room_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          room = ::Room.find_by(id: params[:room_id])
          return error_response("Room not found", code: "not_found") unless room
          return error_response("Direct rooms cannot be converted", code: "forbidden") if room.direct?

          project = resolve_project_for(room, params)
          return error_response("Project not found", code: "not_found") unless project

          existing_project_room = project.rooms.projects.where.not(id: room.id).first
          if existing_project_room
            return error_response(
              "Project already has a project room (room_id=#{existing_project_room.id})",
              code: "validation_error"
            )
          end

          if room.is_a?(::Rooms::Project) && room.project_id == project.id
            return success_response({
              room_id: room.id,
              room_name: room.name,
              room_type: room.type,
              project_id: room.project_id,
              converted: false,
              message: "Room is already the project room for this project"
            })
          end

          room.update!(
            type: "Rooms::Project",
            project: project,
            name: room.name.presence || project.slug
          )

          room.memberships.grant_to(agent) unless agent.memberships.exists?(room_id: room.id)

          success_response({
            room_id: room.id,
            room_name: room.name,
            room_type: room.type,
            project_id: room.project_id,
            project_slug: project.slug,
            converted: true
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end

        private

        def resolve_project_for(room, params)
          if params[:project_id].present?
            ::Project.find_by(id: params[:project_id])
          elsif params[:project_path].present?
            ::Project.find_or_create_for_path(params[:project_path])
          else
            room.project
          end
        end
      end
    end
  end
end