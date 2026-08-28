class Users::ProjectsController < ApplicationController
  DEFAULT_CHANNEL_DEFINITIONS = {
    "specifications" => "specifications",
    "releases" => "releases"
  }.freeze

  before_action :set_company_context
  before_action :ensure_permission_to_create_projects, only: %i[ new create ]
  before_action :set_project, only: %i[ overview status all_hands knowledge ]

  def new
    @project = Project.new(private: false)
  end

  def create
    @project = Project.new(project_params)
    selected_member_users = selected_human_member_users
    selected_channel_names = selected_default_channel_names

    if @project.name.blank?
      @project.errors.add(:name, "can't be blank")
      @selected_member_users = selected_member_users
      render :new, status: :unprocessable_entity
      return
    end

    slug = next_unique_slug(@project.short_code.presence || @project.name)
    @project.slug = slug
    @project.path = next_unique_path_for(slug)

    ActiveRecord::Base.transaction do
      @project.save!
      @project.project_users.find_or_create_by!(user: Current.user)

      project_room = @project.ensure_project_room!
      project_room.update!(private: @project.private?) if project_room.private != @project.private?
      Membership.find_or_create_by!(room: project_room, participant: Current.user)

      selected_member_users.each do |user|
        next if user == Current.user

        @project.project_users.find_or_create_by!(user: user)
        Membership.find_or_create_by!(room: project_room, participant: user)
      end

      create_default_channels!(project_room, selected_channel_names)
    end

    broadcast_sidebar_refresh_for(selected_member_users)

    redirect_to user_company_project_overview_path(user_id: "me", id: @project.id), notice: "Project created"
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def overview
  end

  def status
  end

  def all_hands
  end

  def knowledge
  end

  private
    def ensure_permission_to_create_projects
      return if Current.user.administrator? || !Current.account.settings.restrict_room_creation_to_administrators?

      head :forbidden
    end

    def project_params
      params.fetch(:project, {}).permit(:name, :short_code, :description, :private)
    end

    def next_unique_slug(base_value)
      base_slug = base_value.to_s.parameterize.presence || "project"
      candidate = base_slug
      suffix = 2

      while Project.exists?(slug: candidate)
        candidate = "#{base_slug}-#{suffix}"
        suffix += 1
      end

      candidate
    end

    def next_unique_path_for(slug)
      base_path = "/manual/#{slug}"
      candidate = base_path
      suffix = 2

      while Project.exists?(path: candidate)
        candidate = "#{base_path}-#{suffix}"
        suffix += 1
      end

      candidate
    end

    def set_company_context
      @account = Current.account
      @users = User.active.without_bots.ordered.limit(50)
      @selected_member_users = selected_human_member_users
      @selected_default_channel_keys = selected_default_channel_keys
      @bots = @account.allowed_bot_users
      @projects = Current.user.projects.sort_by { |project| project.display_name.to_s.downcase }.first(6)
      @rooms_count = Current.user.rooms.without_directs.active.count
      @messages_this_week = Current.user.reachable_messages.where(created_at: 1.week.ago..Time.current).count
    end

    def selected_default_channel_keys
      values = params[:default_channel_keys]
      return DEFAULT_CHANNEL_DEFINITIONS.keys if values.nil?

      Array(values)
        .filter_map { |value| value.to_s.presence }
        .select { |value| DEFAULT_CHANNEL_DEFINITIONS.key?(value) }
        .uniq
    end

    def selected_default_channel_names
      selected_default_channel_keys.map { |key| DEFAULT_CHANNEL_DEFINITIONS[key] }
    end

    def create_default_channels!(project_room, channel_names)
      channel_names.each do |channel_name|
        Rooms::Open.create_for(
          {
            name: channel_name,
            project_id: @project.id,
            parent_id: project_room.id,
            private: @project.private?
          },
          users: Current.user
        )
      end
    end

    def selected_human_member_users
      selected_ids = params.fetch(:member_user_ids, [])
      ids = selected_ids.filter_map do |value|
        value.to_i if value.to_i.positive?
      end.uniq

      users = User.active.without_bots.where(id: ids).ordered.to_a
      users << Current.user unless users.any? { |user| user.id == Current.user.id }
      users.uniq { |user| user.id }
    end

    def set_project
      @project = Current.user.projects.find_by(id: params[:id])
      raise ActiveRecord::RecordNotFound if @project.blank?
    end

    def broadcast_sidebar_refresh_for(users)
      users.uniq.each do |user|
        broadcast_replace_to user, :rooms,
          target: helpers.sidebar_refresh_dom_id(user),
          partial: "users/sidebars/refresh_signal",
          locals: { user: user, trigger: true }
      end
    end
end