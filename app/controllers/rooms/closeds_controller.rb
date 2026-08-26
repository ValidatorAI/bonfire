class Rooms::ClosedsController < RoomsController
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
    @room  = Rooms::Closed.new(name: DEFAULT_ROOM_NAME, project: @project)
    @users = User.active.ordered
    @agents = Agent.active
  end

  def create
    room_attributes = room_params
    if @project
      project_room = @project.ensure_project_room!
      room_attributes[:project_id] = @project.id
      room_attributes[:parent_id] = project_room.id
    end

    room = Rooms::Closed.create_for(room_attributes, users: grantees)

    broadcast_create_room(room)
    redirect_to room_url(room)
  end

  def edit
    selected_user_ids = @room.users.pluck(:id)
    @selected_users, @unselected_users = User.active.ordered.partition { |user| selected_user_ids.include?(user.id) }

    selected_agent_ids = @room.agents.pluck(:id)
    @selected_agents, @unselected_agents = Agent.active.partition { |agent| selected_agent_ids.include?(agent.id) }
  end

  def update
    @room.update! room_params
    @room.memberships.revise(granted: grantees, revoked: revokees)

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

    # Allows us to edit an open room and turn it into a closed one on saving.
    def force_room_type
      @room = @room.becomes!(Rooms::Closed)
    end

    def grantees
      User.where(id: grantee_ids)
    end

    def revokees
      @room.users.where.not(id: grantee_ids)
    end

    def grantee_ids
      params.fetch(:user_ids, [])
    end

    def broadcast_create_room(room)
      each_user_and_html_for(room) do |user, html|
        broadcast_prepend_to user, :rooms, target: :shared_rooms, html: html
      end
    end

    def broadcast_update_room
      each_user_and_html_for(@room) do |user, html|
        broadcast_replace_to user, :rooms, target: [ @room, :list ], html: html
      end
    end

    def each_user_and_html_for(room)
      # Optimization to avoid rendering the same partial for every user
      html = render_to_string(partial: "users/sidebars/rooms/shared", locals: { room: room })

      room.users.each { |user| yield user, html }
    end
end
