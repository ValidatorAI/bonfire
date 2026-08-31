class CompanyStatusItem < ApplicationRecord
  CATEGORIES = %w[
    priorities
    progress
    risks
    dependencies
    changes
    decisions
    learnings
  ].freeze

  belongs_to :company_status_period

  validates :category, inclusion: { in: CATEGORIES }

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :for_category, ->(category) { where(category: category) }

  def outcome
    subtitle.presence || self[:outcome] || ""
  end

  def outcome=(val)
    if has_attribute?(:subtitle)
      self.subtitle = val
    else
      self[:outcome] = val
    end
  end

  def status_label
    self[:status]
  end

  def status_label=(val)
    self[:status] = val
  end

  def as_status_payload
    item_title = title.presence || text.presence || subtitle.presence || ""
    item_outcome = outcome.presence || ""

    {
      id: id.to_s,
      title: item_title,
      outcome: item_outcome,
      label: item_title,
      percent: percent&.to_s,
      color: color,
      evidence: evidence,
      type: severity,
      icon: icon,
      desc: description,
      from: from_name,
      to: to_name,
      text: text.presence || item_title,
      details: {
        category: detail_category.presence || category.to_s.singularize.titleize,
        description: description,
        owner: owner,
        targetDate: target_date,
        status: status.presence || "Open",
        impact: impact,
        actions: actions || []
      }
    }
  end
end
