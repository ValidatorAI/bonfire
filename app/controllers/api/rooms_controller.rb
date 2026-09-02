module Api
  class RoomsController < Api::BaseController
    ROOM_FIELDS = %i[
      id name type description private parent_id project_id creator_id
      archived_at created_at updated_at
    ].freeze

    def index
      project = find_project(params[:project_id])
      return render json: { error: "Project not found" }, status: :not_found unless project

      render json: project.rooms.as_json(only: ROOM_FIELDS)
    end

    def show
      project = find_project(params[:project_id])
      return render json: { error: "Project not found" }, status: :not_found unless project

      room = find_room(project, params[:id])
      return render json: { error: "Room not found" }, status: :not_found unless room

      render json: room.as_json(only: ROOM_FIELDS)
    end
  end
end
