class CreateProjectUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :project_users do |t|
      t.references :project, null: false, foreign_key: true, index: false
      t.references :user, null: false, foreign_key: true, index: false

      t.timestamps
    end

    add_index :project_users, :project_id
    add_index :project_users, :user_id
    add_index :project_users, [ :project_id, :user_id ], unique: true
  end
end