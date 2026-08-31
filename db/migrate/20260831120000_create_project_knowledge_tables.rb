class CreateProjectKnowledgeTables < ActiveRecord::Migration[8.0]
  def change
    create_table :project_obsidian_notes, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.string :title, null: false
      t.string :tags
      t.text :content
      t.string :html_source_type, default: "internal_file", null: false
      t.string :html_source_path
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :project_obsidian_notes, :project_id unless index_exists?(:project_obsidian_notes, :project_id)
    add_index :project_obsidian_notes, :position unless index_exists?(:project_obsidian_notes, :position)
    add_foreign_key :project_obsidian_notes, :projects unless foreign_key_exists?(:project_obsidian_notes, :projects)

    create_table :project_external_assets, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.string :title, null: false
      t.string :doc_type
      t.string :icon
      t.string :source_type, default: "external_url", null: false
      t.string :url, null: false
      t.string :meta_text
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :project_external_assets, :project_id unless index_exists?(:project_external_assets, :project_id)
    add_index :project_external_assets, :position unless index_exists?(:project_external_assets, :position)
    add_foreign_key :project_external_assets, :projects unless foreign_key_exists?(:project_external_assets, :projects)

    create_table :project_adrs, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.string :identifier, null: false
      t.string :title, null: false
      t.date :decision_date
      t.string :status, default: "proposed", null: false
      t.string :file_path
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :project_adrs, :project_id unless index_exists?(:project_adrs, :project_id)
    add_index :project_adrs, :identifier unless index_exists?(:project_adrs, :identifier)
    add_index :project_adrs, :position unless index_exists?(:project_adrs, :position)
    add_foreign_key :project_adrs, :projects unless foreign_key_exists?(:project_adrs, :projects)

    create_table :project_knowledge_activities, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.string :actor_name, null: false
      t.string :actor_color
      t.string :action_text, null: false
      t.string :target_path
      t.string :target_url
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :project_knowledge_activities, :project_id unless index_exists?(:project_knowledge_activities, :project_id)
    add_index :project_knowledge_activities, :position unless index_exists?(:project_knowledge_activities, :position)
    add_foreign_key :project_knowledge_activities, :projects unless foreign_key_exists?(:project_knowledge_activities, :projects)
  end
end
