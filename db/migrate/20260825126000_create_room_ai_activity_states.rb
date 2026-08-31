class CreateRoomAiActivityStates < ActiveRecord::Migration[8.0]
  def change
    create_table :room_ai_activity_states do |t|
      t.integer :room_id
      t.integer :agent_id
      t.integer :state, default: 0, null: false
      t.datetime :started_at

      t.timestamps
    end

    add_index :room_ai_activity_states, [ :room_id, :agent_id ], unique: true
    add_index :room_ai_activity_states, :updated_at
  end
end