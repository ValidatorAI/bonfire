class AddBudgetAndRoadmapToProjects < ActiveRecord::Migration[8.0]
  def change
    add_column :projects, :budget_total, :decimal, precision: 12, scale: 2, default: 0, null: false
    add_column :projects, :budget_spent, :decimal, precision: 12, scale: 2, default: 0, null: false
    add_column :projects, :roadmap, :text
  end
end
