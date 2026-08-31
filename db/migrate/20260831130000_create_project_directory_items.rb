class CreateProjectDirectoryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :project_directory_items, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.integer :parent_id
      t.string :name, null: false
      t.string :item_type, default: "file", null: false
      t.string :file_path
      t.text :content
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :project_directory_items, :project_id unless index_exists?(:project_directory_items, :project_id)
    add_index :project_directory_items, :parent_id unless index_exists?(:project_directory_items, :parent_id)
    add_index :project_directory_items, :position unless index_exists?(:project_directory_items, :position)
    add_foreign_key :project_directory_items, :projects unless foreign_key_exists?(:project_directory_items, :projects)
    add_foreign_key :project_directory_items, :project_directory_items, column: :parent_id unless foreign_key_exists?(:project_directory_items, :project_directory_items, column: :parent_id)
  end
end
