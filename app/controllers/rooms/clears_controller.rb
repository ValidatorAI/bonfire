module Rooms
  class ClearsController < ApplicationController
    before_action :set_room
    before_action :ensure_can_administer

    def create
      @room.messages.destroy_all
      redirect_to @room, notice: "All messages cleared"
    end

    private
      def set_room
        @room = Current.user.rooms.find(params[:room_id])
      end

      def ensure_can_administer
        head :forbidden unless Current.user.can_administer?(@room)
      end
  end
end
