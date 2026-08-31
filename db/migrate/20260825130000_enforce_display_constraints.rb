class EnforceDisplayConstraints < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE projects
      SET name = slug
      WHERE name IS NULL
    SQL

    execute <<~SQL
      UPDATE users
      SET display_name = name
      WHERE display_name IS NULL
    SQL

    change_column_null :projects, :name, false
    change_column_null :users, :display_name, false
  end

  def down
    change_column_null :projects, :name, true
    change_column_null :users, :display_name, true
  end
end