module Api
  class RoomsController < Api::BaseController
    def index
      project = find_project(params[:project_id])
      return render json: { error: "Project not found" }, status: :not_found unless project

      render json: project.rooms.as_json(only: %i[
        id name type description private parent_id archived_at created_at updated_at
      ])
    end
  end
end
