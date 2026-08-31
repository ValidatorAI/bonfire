class ProjectAllHandsMeeting < ApplicationRecord
  belongs_to :project

  has_many :takeaways, class_name: "ProjectAllHandsTakeaway", dependent: :destroy
  has_many :action_items, class_name: "ProjectAllHandsActionItem", dependent: :destroy
  has_many :decisions, class_name: "ProjectAllHandsDecision", dependent: :destroy

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc, held_at: :desc, created_at: :desc) }

  def pending_action_items_count
    action_items.pending.count
  end

  def formatted_held_date
    held_at.present? ? held_at.strftime("%B %-d, %Y") : nil
  end

  def metadata_line
    parts = []
    parts << formatted_held_date if formatted_held_date.present?
    parts << "#{duration_minutes} mins" if duration_minutes.present?
    parts << "Led by @#{leader_name}" if leader_name.present?
    parts.join(" • ")
  end
end
