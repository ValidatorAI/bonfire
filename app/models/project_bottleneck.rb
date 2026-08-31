class ProjectBottleneck < ApplicationRecord
  belongs_to :project

  validates :title, presence: true

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :active, -> { where(resolved_at: nil) }
  scope :resolved, -> { where.not(resolved_at: nil) }

  def active?
    resolved_at.blank? && severity != "resolved"
  end

  def resolve!
    update!(resolved_at: Time.current, severity: "resolved")
  end
end
