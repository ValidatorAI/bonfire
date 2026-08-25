class BackfillDisplayFields < ActiveRecord::Migration[8.0]
  def up
    execute <<~SQL
      UPDATE projects
      SET name = slug
      WHERE (name IS NULL OR TRIM(name) = '')
        AND slug IS NOT NULL
        AND TRIM(slug) != ''
    SQL

    execute <<~SQL
      UPDATE users
      SET display_name = name
      WHERE (display_name IS NULL OR TRIM(display_name) = '')
        AND name IS NOT NULL
        AND TRIM(name) != ''
    SQL
  end

  def down
    # Irreversible data migration: preserves user-entered values after backfill.
  end
end