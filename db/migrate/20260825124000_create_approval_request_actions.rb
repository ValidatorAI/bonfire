class CreateApprovalRequestActions < ActiveRecord::Migration[8.0]
  def change
    create_table :approval_request_actions do |t|
      t.integer :approval_request_id
      t.string :actor_type
      t.integer :actor_id
      t.string :action
      t.text :note

      t.timestamps
    end
  end
end