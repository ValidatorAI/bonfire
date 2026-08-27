class Rooms::ProjectsController < RoomsController
  skip_before_action :set_room, only: %i[ edit update ]
  before_action :set_project_room, only: %i[ edit update ]
  before_action :set_project, only: %i[ edit update ]
  before_action :ensure_can_administer, only: %i[ update ]

  def edit
    @teammates = @room.users.active.ordered
    @channels = project_channels_scope
  end

  def update
    case params[:intent]
    when "archive_project"
      archive_project
    when "delete_project"
      delete_project
    when "archive_channel"
      archive_channel
    else
      update_project_details
    end
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

    def set_project
      @project = @room.project
      return if @project.present?

      redirect_to root_url, alert: "Project not found or inaccessible"
    end

    def update_project_details
      ActiveRecord::Base.transaction do
        @project.update!(project_params)
        @room.update!(
          name: @project.display_name,
          description: @project.description,
          private: @project.private
        )
      end

      broadcast_update_room
      redirect_to edit_rooms_project_url(@project.id, by: "project"), notice: "Project settings updated"
    end

    def archive_project
      rooms = @project.rooms.active.to_a
      rooms.each(&:archive!)
      rooms.each { |room| broadcast_remove_to :rooms, target: [ room, :list ] }

      redirect_to root_url, notice: "Project archived"
    end

    def delete_project
      rooms = @project.rooms.to_a
      @project.destroy!
      rooms.each { |room| broadcast_remove_to :rooms, target: [ room, :list ] }

      redirect_to root_url, notice: "Project deleted"
    end

    def archive_channel
      channel = project_channels_scope.find_by(id: params[:channel_id])
      unless channel
        redirect_to edit_rooms_project_url(@project.id, by: "project"), alert: "Channel not found"
        return
      end

      channel.archive!
      broadcast_remove_to :rooms, target: [ channel, :list ]
      redirect_to edit_rooms_project_url(@project.id, by: "project"), notice: "Channel archived"
    end

    def project_channels_scope
      @project.rooms.active.where.not(id: @room.id).ordered
    end

    def project_params
      params.fetch(:project, {}).permit(:name, :description, :private)
    end

    def broadcast_update_room
      broadcast_replace_to :rooms, target: [ @room, :list ], partial: "users/sidebars/rooms/shared", locals: { room: @room }
    end
end
