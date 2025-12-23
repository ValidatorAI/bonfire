class CreateFileReservations < ActiveRecord::Migration[8.0]
  def change
    create_table :file_reservations do |t|
      t.references :project, null: false, foreign_key: true
      t.references :agent, null: false, foreign_key: true
      t.json :patterns, null: false, default: []
      t.boolean :exclusive, null: false, default: true
      t.text :reason
      t.datetime :expires_at, null: false
      t.timestamps
    end

    add_index :file_reservations, [ :project_id, :expires_at ]
    add_index :file_reservations, :expires_at
  end
end
