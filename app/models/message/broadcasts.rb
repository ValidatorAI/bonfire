module Message::Broadcasts
  def broadcast_create
    broadcast_append_to room, :messages, target: [ room, :messages ]
    broadcast_to_parent_room
    ActionCable.server.broadcast("unread_rooms", { roomId: room.id })
  end

  def broadcast_remove
    broadcast_remove_to room, :messages
    broadcast_remove_from_parent_room
  end

  private
    def broadcast_to_parent_room
      return unless room.parent.present?

      parent_room = room.parent

      # Ensure feed container is visible on parent room
      broadcast_update_to parent_room, :messages,
        target: ActionView::RecordIdentifier.dom_id(room, :topic_header_count),
        html: "#{ActionController::Base.helpers.pluralize(room.messages.count, 'message')} • Click to open thread"

      # Append message to child topic block on parent room
      broadcast_append_to parent_room, :messages,
        target: ActionView::RecordIdentifier.dom_id(room, :topic_messages),
        partial: "messages/message",
        locals: { message: self }

      ActionCable.server.broadcast("unread_rooms", { roomId: parent_room.id })
    end

    def broadcast_remove_from_parent_room
      return unless room.parent.present?

      parent_room = room.parent

      # Remove message from parent room stream
      broadcast_remove_to parent_room, :messages

      # Update count
      broadcast_update_to parent_room, :messages,
        target: ActionView::RecordIdentifier.dom_id(room, :topic_header_count),
        html: "#{ActionController::Base.helpers.pluralize(room.messages.count, 'message')} • Click to open thread"
    end
end
