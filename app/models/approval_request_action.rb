class ApprovalRequestAction < ApplicationRecord
  belongs_to :approval_request, optional: true
  belongs_to :actor, polymorphic: true, optional: true

  validates :action, length: { maximum: 100 }, allow_blank: true

  scope :recent, -> { order(created_at: :desc) }
end