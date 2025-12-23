class Agent < ApplicationRecord
  include Agent::Authenticatable
  include Agent::Mentionable
  include Agent::Presence

  belongs_to :project

  has_many :memberships, as: :participant, dependent: :delete_all
  has_many :rooms, through: :memberships
  has_many :messages, as: :creator, dependent: :nullify
  has_many :file_reservations, dependent: :destroy

  enum :status, { offline: 0, online: 1, idle: 2 }, default: :offline

  validates :name, presence: true, uniqueness: { scope: :project_id }
  validates :program, presence: true
  validates :model, presence: true

  before_validation :generate_memorable_name, on: :create, if: -> { name.blank? }
  before_create :generate_api_token

  scope :active, -> { where(status: [ :online, :idle ]) }
  scope :ordered, -> { order("LOWER(name)") }

  # Duck-type compatibility with User for views
  def title
    "#{name} (#{program})"
  end

  def initials
    name.scan(/[A-Z]/).join.presence || name.first(2).upcase
  end

  def bot?
    true
  end

  def avatar_attachment
    nil
  end

  private

  def generate_memorable_name
    self.name = Agent::NameGenerator.generate(project)
  end

  def generate_api_token
    self.api_token = SecureRandom.alphanumeric(24)
  end
end
