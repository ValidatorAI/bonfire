class CreateProjectStatusTables < ActiveRecord::Migration[8.0]
  def change
    change_table :projects do |t|
      t.string :current_phase, default: "Phase 1: Project Setup" unless column_exists?(:projects, :current_phase)
      t.integer :progress_percent, default: 0 unless column_exists?(:projects, :progress_percent)
      t.text :recently_completed unless column_exists?(:projects, :recently_completed)
    end

    create_table :project_bottlenecks, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.string :title, null: false
      t.text :description
      t.string :severity, default: "active"
      t.integer :position, default: 0, null: false
      t.datetime :resolved_at

      t.timestamps
    end

    add_index :project_bottlenecks, :project_id unless index_exists?(:project_bottlenecks, :project_id)
    add_index :project_bottlenecks, :position unless index_exists?(:project_bottlenecks, :position)
    add_foreign_key :project_bottlenecks, :projects unless foreign_key_exists?(:project_bottlenecks, :projects)

    create_table :project_todos, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.string :title, null: false
      t.string :meta_text
      t.boolean :completed, default: false, null: false
      t.datetime :completed_at
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :project_todos, :project_id unless index_exists?(:project_todos, :project_id)
    add_index :project_todos, :position unless index_exists?(:project_todos, :position)
    add_foreign_key :project_todos, :projects unless foreign_key_exists?(:project_todos, :projects)

    create_table :project_knowledge_items, if_not_exists: true do |t|
      t.integer :project_id, null: false
      t.string :title, null: false
      t.string :badge
      t.text :description, null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :project_knowledge_items, :project_id unless index_exists?(:project_knowledge_items, :project_id)
    add_index :project_knowledge_items, :position unless index_exists?(:project_knowledge_items, :position)
    add_foreign_key :project_knowledge_items, :projects unless foreign_key_exists?(:project_knowledge_items, :projects)
  end
end
