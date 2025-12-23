class AddPolymorphicParticipantToMemberships < ActiveRecord::Migration[8.0]
  def change
    add_column :memberships, :participant_type, :string

    reversible do |dir|
      dir.up do
        execute "UPDATE memberships SET participant_type = 'User'"
      end
    end

    change_column_null :memberships, :participant_type, false

    rename_column :memberships, :user_id, :participant_id

    # Remove old unique index if it exists, then add new polymorphic one
    remove_index :memberships, [ :room_id, :user_id ], if_exists: true
    add_index :memberships, [ :room_id, :participant_type, :participant_id ],
              unique: true,
              name: "index_memberships_on_room_and_participant"
    add_index :memberships, [ :participant_type, :participant_id ]
  end
end
