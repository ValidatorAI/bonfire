class Users::ProjectsController < ApplicationController
  before_action :set_company_context
  before_action :ensure_permission_to_create_projects, only: %i[ new create ]
  before_action :set_project, only: %i[ overview status all_hands knowledge ]

  def new
    @project = Project.new(private: false)
  end

  def create
    @project = Project.new(project_params)
    selected_member_users = selected_human_member_users

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
      Membership.find_or_create_by!(room: project_room, participant: Current.user)

      selected_member_users.each do |user|
        next if user == Current.user

        @project.project_users.find_or_create_by!(user: user)
        Membership.find_or_create_by!(room: project_room, participant: user)
      end
    end

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
      @bots = @account.allowed_bot_users
      @projects = Current.user.projects.sort_by { |project| project.display_name.to_s.downcase }.first(6)
      @rooms_count = Current.user.rooms.without_directs.active.count
      @messages_this_week = Current.user.reachable_messages.where(created_at: 1.week.ago..Time.current).count
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
end