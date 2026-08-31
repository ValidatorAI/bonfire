class ProjectAllHandsActionItem < ApplicationRecord
  belongs_to :meeting, class_name: "ProjectAllHandsMeeting", foreign_key: :project_all_hands_meeting_id

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :pending, -> { where(completed: false) }
  scope :completed, -> { where(completed: true) }

  def pending?
    !completed?
  end

  def toggle_completed!
    update!(
      completed: !completed?,
      completed_at: (!completed? ? Time.current : nil)
    )
  end
end
