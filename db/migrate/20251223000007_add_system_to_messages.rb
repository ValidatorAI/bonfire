class AddSystemToMessages < ActiveRecord::Migration[8.0]
  def change
    add_column :messages, :system, :boolean, default: false, null: false
    add_column :messages, :system_type, :string
  end
end
