class Rooms::DirectsController < RoomsController
  before_action :set_room, only: %i[ edit destroy ]
  def new
    @room = Rooms::Direct.new
  end

  def create
    room = Rooms::Direct.find_or_create_for(selected_users)

    broadcast_create_room(room)
    if room.previously_new_record?
      group_id = SecureRandom.uuid
      record_room_event("room_created", room, group_id: group_id)
      record_room_event("direct_conversation_created", room, group_id: group_id)
      room.users.find_each { |user| record_room_member_added(room, user, group_id: group_id) }
    end
    redirect_to room_url(room)
  end

  def edit
  end

  private
    def selected_users
      User.where(id: selected_users_ids.including(Current.user.id))
    end

    def selected_users_ids
      params.fetch(:user_ids, [])
    end

    def broadcast_create_room(room)
      room.memberships.each do |membership|
        membership.broadcast_prepend_to membership.user, :rooms, target: :direct_rooms, partial: "users/sidebars/rooms/direct"
      end
    end

    def record_room_member_added(room, user, group_id: nil)
      OutputEvents::Recorder.record(
        event_type: "room_member_added",
        event_id: room.id,
        group_id: group_id,
        actor: Current.user,
        target_type: "Room",
        data: { "member" => { "type" => "User", "id" => user.id } }
      )
    end

    # All users in a direct room can administer it
    def ensure_can_administer
      true
    end
end
