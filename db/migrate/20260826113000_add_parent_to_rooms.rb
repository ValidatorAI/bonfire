class AddParentToRooms < ActiveRecord::Migration[8.1]
  def change
    add_reference :rooms, :parent, null: true, foreign_key: { to_table: :rooms }
  end
end
