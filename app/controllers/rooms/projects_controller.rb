class Rooms::ProjectsController < RoomsController
  before_action :set_room, only: %i[ edit update ]
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
    def broadcast_update_room
      broadcast_replace_to :rooms, target: [ @room, :list ], partial: "users/sidebars/rooms/shared", locals: { room: @room }
    end
end
