class CreateApprovalRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :approval_requests do |t|
      t.integer :room_id
      t.integer :message_id
      t.integer :agent_id
      t.string :request_type
      t.json :payload
      t.integer :status, default: 0, null: false
      t.datetime :requested_at
      t.datetime :resolved_at
      t.integer :resolved_by_id

      t.timestamps
    end
  end
end