class CreateAttentionItems < ActiveRecord::Migration[8.0]
  def change
    create_table :attention_items do |t|
      t.integer :project_id
      t.integer :room_id
      t.string :source_type
      t.integer :source_id
      t.string :category
      t.string :title
      t.text :meta_text
      t.boolean :overdue, default: false, null: false
      t.boolean :ai_confirm, default: false, null: false
      t.integer :status, default: 0, null: false
      t.datetime :due_at
      t.datetime :resolved_at
      t.integer :resolved_by_id

      t.timestamps
    end
  end
end