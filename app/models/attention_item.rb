class AttentionItem < ApplicationRecord
  belongs_to :project, optional: true
  belongs_to :room, optional: true
  belongs_to :source, polymorphic: true, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true

  enum :status, { pending: 0, resolved: 1, dismissed: 2 }, default: :pending

  validates :category, length: { maximum: 100 }, allow_blank: true
  validates :title, length: { maximum: 255 }, allow_blank: true

  scope :open_items, -> { where(status: :pending) }
  scope :resolved_items, -> { where(status: :resolved) }
  scope :overdue_items, -> { where(overdue: true) }
  scope :recent, -> { order(created_at: :desc) }
end