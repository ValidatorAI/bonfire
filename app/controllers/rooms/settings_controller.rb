module Rooms
  class SettingsController < ApplicationController
    include RoomScoped

    before_action :ensure_can_administer, only: :update

    def show
      @users = @room.users.ordered
      @bots = @room.agents.ordered
      @available_users = User.active.ordered.where.not(id: @users.select(:id))
      @available_bots = available_bots_scope.where.not(id: @bots.select(:id))

      render layout: false
    end

    def update
      case params[:intent]
      when "add_user"
        add_user
      when "remove_user"
        remove_user
      when "add_agent"
        add_agent
      when "remove_agent"
        remove_agent
      when "toggle_private"
        toggle_private
      end

      redirect_to room_settings_path(@room)
    end

    private
      def ensure_can_administer
        head :forbidden unless Current.user.can_administer?(@room)
      end

      def add_user
        user = User.active.find_by(id: params[:participant_id])
        return if user.blank?

        @room.memberships.grant_to(user)
        broadcast_room_added_for(user)
      end

      def remove_user
        user = @room.users.find_by(id: params[:participant_id])
        return if user.blank?
        return if user == Current.user

        @room.memberships.revoke_from(user)
        broadcast_room_removed_for(user)
      end

      def add_agent
        agent = available_bots_scope.find_by(id: params[:participant_id])
        return if agent.blank?

        @room.memberships.grant_to(agent)
      end

      def remove_agent
        agent = @room.agents.find_by(id: params[:participant_id])
        return if agent.blank?

        @room.memberships.revoke_from(agent)
      end

      def toggle_private
        @room.update!(private: params[:room].present? && params[:room][:private] == "1")
      end

      def available_agents_scope
        @room.project ? @room.project.agents.ordered : Agent.none
      end

      alias_method :available_bots_scope, :available_agents_scope

      def broadcast_room_added_for(user)
        html = render_to_string(partial: "users/sidebars/rooms/shared", locals: { room: @room })

        broadcast_prepend_to user, :rooms, target: :shared_rooms, html: html
      end

      def broadcast_room_removed_for(user)
        broadcast_remove_to user, :rooms, target: [ @room, :list ]
      end
  end
end
