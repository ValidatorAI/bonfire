class ProjectAllHandsTakeaway < ApplicationRecord
  belongs_to :meeting, class_name: "ProjectAllHandsMeeting", foreign_key: :project_all_hands_meeting_id

  validates :category, presence: true
  validates :content, presence: true

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
end
