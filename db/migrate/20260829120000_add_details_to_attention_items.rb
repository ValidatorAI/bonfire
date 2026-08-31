class AddDetailsToAttentionItems < ActiveRecord::Migration[8.0]
  def change
    add_column :attention_items, :user_id, :integer
    add_column :attention_items, :action_label, :string
    add_column :attention_items, :target_type, :string
    add_column :attention_items, :target_id, :integer

    add_index :attention_items, :user_id
    add_index :attention_items, [ :user_id, :status, :category ]
    add_foreign_key :attention_items, :users, column: :user_id
  end
end
