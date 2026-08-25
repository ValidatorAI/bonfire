class AddForeignKeysForWorkflows < ActiveRecord::Migration[8.0]
  def change
    add_foreign_key :approval_requests, :rooms unless foreign_key_exists?(:approval_requests, :rooms)
    add_foreign_key :approval_requests, :messages unless foreign_key_exists?(:approval_requests, :messages)
    add_foreign_key :approval_requests, :agents unless foreign_key_exists?(:approval_requests, :agents)
    add_foreign_key :approval_requests, :users, column: :resolved_by_id unless foreign_key_exists?(:approval_requests, :users, column: :resolved_by_id)

    add_foreign_key :approval_request_actions, :approval_requests unless foreign_key_exists?(:approval_request_actions, :approval_requests)

    add_foreign_key :attention_items, :projects unless foreign_key_exists?(:attention_items, :projects)
    add_foreign_key :attention_items, :rooms unless foreign_key_exists?(:attention_items, :rooms)
    add_foreign_key :attention_items, :users, column: :resolved_by_id unless foreign_key_exists?(:attention_items, :users, column: :resolved_by_id)

    add_foreign_key :room_ai_activity_states, :rooms unless foreign_key_exists?(:room_ai_activity_states, :rooms)
    add_foreign_key :room_ai_activity_states, :agents unless foreign_key_exists?(:room_ai_activity_states, :agents)
  end
end