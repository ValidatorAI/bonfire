class AddProjectToRooms < ActiveRecord::Migration[8.0]
  def change
    add_reference :rooms, :project, foreign_key: true, null: true
    add_column :rooms, :description, :text
    add_column :rooms, :archived_at, :datetime

    add_index :rooms, [ :project_id, :type ]
    add_index :rooms, :archived_at
  end
end
