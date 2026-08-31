class ProjectKnowledgeActivity < ApplicationRecord
  belongs_to :project

  validates :actor_name, presence: true
  validates :action_text, presence: true

  scope :ordered, -> { order(position: :asc, created_at: :desc) }

  def actor_initial
    actor_name.to_s.strip[0]&.upcase || "U"
  end
end
