class FixMembershipsUniqueIndex < ActiveRecord::Migration[8.2]
  def change
    # Remove the incorrect unique index that doesn't include participant_type
    # This was blocking User id=1 from joining rooms where Agent id=1 exists
    remove_index :memberships, [:room_id, :participant_id], unique: true, if_exists: true

    # The correct unique index on (room_id, participant_type, participant_id) already exists
    # as "index_memberships_on_room_and_participant"
  end
end
