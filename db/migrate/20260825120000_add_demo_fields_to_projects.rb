class AddDemoFieldsToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :name, :string
    add_column :projects, :short_code, :string
    add_column :projects, :description, :text
    add_column :projects, :private, :boolean, default: false, null: false
  end
end