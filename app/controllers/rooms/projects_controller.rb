class Rooms::ProjectsController < RoomsController
  skip_before_action :set_room, only: %i[ edit update ]
  before_action :set_project_room, only: %i[ edit update ]
  before_action :ensure_can_administer, only: %i[ update ]

  def edit
    @agents = @room.agents
  end

  def update
    @room.update! room_params
    broadcast_update_room
    redirect_to room_url(@room)
  end

  private
    def set_project_room
      room = if params[:by] == "project"
        project = Current.user.projects.find_by(id: params[:id])
        project&.ensure_project_room!
      else
        Room.find_by(id: params[:id], type: "Rooms::Project")
      end

      unless room && Current.user.projects.exists?(id: room.project_id)
        redirect_to root_url, alert: "Project not found or inaccessible"
        return
      end

      @room = room
    end

    def broadcast_update_room
      broadcast_replace_to :rooms, target: [ @room, :list ], partial: "users/sidebars/rooms/shared", locals: { room: @room }
    end
end
