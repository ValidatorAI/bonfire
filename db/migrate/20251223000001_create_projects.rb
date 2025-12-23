class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :slug, null: false
      t.string :path, null: false
      t.timestamps
    end

    add_index :projects, :slug, unique: true
    add_index :projects, :path, unique: true
  end
end
