class CreateCompanyStatusTables < ActiveRecord::Migration[8.0]
  def change
    create_table :company_status_periods, if_not_exists: true do |t|
      t.integer :account_id
      t.string :slug, null: false
      t.string :name, null: false
      t.boolean :current, default: false, null: false
      t.integer :position, default: 0, null: false
      t.date :starts_on
      t.date :ends_on

      t.timestamps
    end

    add_index :company_status_periods, :account_id unless index_exists?(:company_status_periods, :account_id)
    add_index :company_status_periods, :slug, unique: true unless index_exists?(:company_status_periods, :slug)
    add_index :company_status_periods, :current unless index_exists?(:company_status_periods, :current)
    add_index :company_status_periods, :position unless index_exists?(:company_status_periods, :position)

    create_table :company_status_items, if_not_exists: true do |t|
      t.integer :company_status_period_id, null: false
      t.string :category, null: false
      t.integer :position, default: 0, null: false
      t.string :title
      t.text :subtitle
      t.text :text
      t.text :description
      t.string :detail_category
      t.string :owner
      t.string :target_date
      t.string :status
      t.text :impact
      t.integer :percent
      t.string :color
      t.text :evidence
      t.string :severity
      t.string :icon
      t.string :from_name
      t.string :to_name
      t.json :actions, default: []

      t.timestamps
    end

    add_index :company_status_items, :company_status_period_id unless index_exists?(:company_status_items, :company_status_period_id)
    add_index :company_status_items, [ :company_status_period_id, :category ] unless index_exists?(:company_status_items, [ :company_status_period_id, :category ])
    add_index :company_status_items, :position unless index_exists?(:company_status_items, :position)

    add_foreign_key :company_status_periods, :accounts unless foreign_key_exists?(:company_status_periods, :accounts)
    add_foreign_key :company_status_items, :company_status_periods unless foreign_key_exists?(:company_status_items, :company_status_periods)
  end
end
