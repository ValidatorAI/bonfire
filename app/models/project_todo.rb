class ProjectTodo < ApplicationRecord
  belongs_to :project

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :pending, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }

  def toggle_completed!
    if completed?
      update!(completed: false, completed_at: nil)
    else
      update!(completed: true, completed_at: Time.current)
    end
  end
end
