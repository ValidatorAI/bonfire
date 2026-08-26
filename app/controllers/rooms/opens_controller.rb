class Rooms::OpensController < RoomsController
  before_action :set_room, only: %i[ show edit update ]
  before_action :ensure_can_administer, only: %i[ update ]
  before_action :remember_last_room_visited, only: :show
  before_action :force_room_type, only: %i[ edit update ]
  before_action :ensure_permission_to_create_rooms, only: %i[ new create ]
  before_action :set_project_for_new_room, only: %i[ new create ]

  DEFAULT_ROOM_NAME = "New room"

  def show
    redirect_to room_url(@room)
  end

  def new
    @room = Rooms::Open.new(name: DEFAULT_ROOM_NAME, project: @project)
    @users = User.active.ordered
    @agents = Agent.active
  end

  def create
    room_attributes = room_params
    room_attributes[:project_id] = @project.id if @project

    room = Rooms::Open.create_for(room_attributes, users: Current.user)

    broadcast_create_room(room)
    redirect_to room_url(room)
  end

  def edit
    @users = User.active.ordered
    @agents = Agent.active
  end

  def update
    @room.update! room_params

    broadcast_update_room
    redirect_to room_url(@room)
  end

  private
    def set_project_for_new_room
      project_id = params[:project_id] || params.dig(:room, :project_id)
      return if project_id.blank?

      @project = Current.user.projects.find_by(id: project_id)
      return if @project

      redirect_to root_url, alert: "Project not found or inaccessible"
    end

    # Allows us to edit a closed room and turn it into an open one on saving.
    def force_room_type
      @room = @room.becomes!(Rooms::Open)
    end

    def broadcast_create_room(room)
      broadcast_prepend_to :rooms, target: :shared_rooms, partial: "users/sidebars/rooms/shared", locals: { room: room }
    end

    def broadcast_update_room
      broadcast_replace_to :rooms, target: [ @room, :list ], partial: "users/sidebars/rooms/shared", locals: { room: @room }
    end
end
