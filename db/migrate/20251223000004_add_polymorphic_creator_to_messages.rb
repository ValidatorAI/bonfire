class AddPolymorphicCreatorToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :creator_type, :string

    reversible do |dir|
      dir.up do
        execute "UPDATE messages SET creator_type = 'User'"
      end
    end

    change_column_null :messages, :creator_type, false

    add_index :messages, [ :creator_type, :creator_id ]
  end
end
