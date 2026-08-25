class AddIndexesForWorkflows < ActiveRecord::Migration[8.0]
  def change
    add_index :attention_items, :status unless index_exists?(:attention_items, :status)
    add_index :attention_items, :due_at unless index_exists?(:attention_items, :due_at)
    add_index :attention_items, :project_id unless index_exists?(:attention_items, :project_id)
    add_index :attention_items, [ :project_id, :status, :due_at ] unless index_exists?(:attention_items, [ :project_id, :status, :due_at ])

    add_index :approval_requests, :status unless index_exists?(:approval_requests, :status)
    add_index :approval_requests, :room_id unless index_exists?(:approval_requests, :room_id)
    add_index :approval_requests, :requested_at unless index_exists?(:approval_requests, :requested_at)
    add_index :approval_requests, [ :room_id, :status, :requested_at ] unless index_exists?(:approval_requests, [ :room_id, :status, :requested_at ])

    add_index :room_ai_activity_states, :room_id unless index_exists?(:room_ai_activity_states, :room_id)
    add_index :room_ai_activity_states, :updated_at unless index_exists?(:room_ai_activity_states, :updated_at)
    add_index :room_ai_activity_states, [ :room_id, :agent_id ], unique: true unless index_exists?(:room_ai_activity_states, [ :room_id, :agent_id ], unique: true)
  end
end