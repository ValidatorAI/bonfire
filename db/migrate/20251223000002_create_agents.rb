class CreateAgents < ActiveRecord::Migration[8.0]
  def change
    create_table :agents do |t|
      t.references :project, null: false, foreign_key: true
      t.string :name, null: false
      t.string :program, null: false
      t.string :model, null: false
      t.text :task_description
      t.integer :status, default: 0, null: false
      t.string :api_token
      t.datetime :last_active_at
      t.timestamps
    end

    add_index :agents, [ :project_id, :name ], unique: true
    add_index :agents, :api_token, unique: true
    add_index :agents, :status
  end
end
