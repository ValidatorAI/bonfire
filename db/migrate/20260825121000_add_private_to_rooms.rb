class AddPrivateToRooms < ActiveRecord::Migration[8.0]
  def change
    add_column :rooms, :private, :boolean, default: false, null: false
  end
end