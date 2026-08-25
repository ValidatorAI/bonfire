class AddSettingsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :display_name, :string
    add_column :users, :job_title, :string
    add_column :users, :timezone, :string
    add_column :users, :preferences, :json
  end
end