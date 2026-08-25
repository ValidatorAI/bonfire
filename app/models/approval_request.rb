class ApprovalRequest < ApplicationRecord
  belongs_to :room, optional: true
  belongs_to :message, optional: true
  belongs_to :agent, optional: true
  belongs_to :resolved_by, class_name: "User", optional: true
  has_many :approval_request_actions, dependent: :delete_all

  enum :status, { pending: 0, approved: 1, denied: 2, canceled: 3 }, default: :pending

  validates :request_type, length: { maximum: 100 }, allow_blank: true
  validate :payload_must_be_object

  scope :open_requests, -> { where(status: :pending) }
  scope :resolved,      -> { where.not(resolved_at: nil) }
  scope :recent,        -> { order(requested_at: :desc, created_at: :desc) }

  private

  def payload_must_be_object
    return if payload.blank? || payload.is_a?(Hash)

    errors.add(:payload, "must be a JSON object")
  end
end