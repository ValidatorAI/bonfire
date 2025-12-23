class AddLastReadAtToMemberships < ActiveRecord::Migration[8.2]
  def change
    add_column :memberships, :last_read_at, :datetime
    add_index :memberships, :last_read_at
  end
end
