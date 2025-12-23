class RemoveUserForeignKeyFromMessages < ActiveRecord::Migration[8.0]
  def change
    # creator_id is polymorphic (can reference User or Agent)
    # so the foreign key to users table must be removed
    remove_foreign_key :messages, :users, column: :creator_id, if_exists: true
  end
end
