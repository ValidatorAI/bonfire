module Api
  class ProjectsController < Api::BaseController
    def show
      project = Project.find_by(id: params[:id]) || Project.find_by(slug: params[:id])
      return render json: { error: "Project not found" }, status: :not_found unless project

      render json: project.as_json(only: %i[
        id name slug path description private short_code current_phase
        progress_percent roadmap recently_completed budget_total budget_spent
        created_at updated_at
      ])
    end
  end
end
