module Rooms
  class SettingsController < ApplicationController
    include RoomScoped

    before_action :ensure_can_administer, only: :update

    def show
      @users = @room.users.without_bots.ordered
      @bot_users = @room.users.active_bots.ordered
      @bots = @room.agents.ordered
      @available_users = available_users_scope.where.not(id: @users.select(:id))
      @available_ai_teammate_options = available_ai_teammate_options

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
        user = available_users_scope.find_by(id: params[:participant_id])
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
        participant = find_available_ai_participant(params[:participant_id])
        return if participant.blank?

        @room.memberships.grant_to(participant)
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

      def available_users_scope
        @room.project ? @room.project.users.active.without_bots.ordered : User.none
      end

      def available_bot_users_scope
        @room.project ? @room.project.users.active_bots.ordered : User.none
      end

      def available_ai_teammate_options
        available_agent_options + available_bot_user_options
      end

      def available_agent_options
        available_agents_scope.where.not(id: @bots.select(:id)).map do |agent|
          [ "#{agent.name} AI", "Agent:#{agent.id}" ]
        end
      end

      def available_bot_user_options
        available_bot_users_scope.where.not(id: @bot_users.select(:id)).map do |bot_user|
          [ "#{bot_user.name} AI", "User:#{bot_user.id}" ]
        end
      end

      def find_available_ai_participant(participant_key)
        key = participant_key.to_s

        # Backward compatibility with legacy numeric values (Agent ids only)
        return available_agents_scope.find_by(id: key) if key.match?(/\A\d+\z/)

        type, id = key.split(":", 2)
        return if id.blank?

        case type
        when "Agent"
          available_agents_scope.find_by(id: id)
        when "User"
          available_bot_users_scope.find_by(id: id)
        end
      end

      def broadcast_room_added_for(user)
        html = render_to_string(partial: "users/sidebars/rooms/shared", locals: { room: @room })

        broadcast_prepend_to user, :rooms, target: :shared_rooms, html: html
      end

      def broadcast_room_removed_for(user)
        broadcast_remove_to user, :rooms, target: [ @room, :list ]
      end
  end
end
