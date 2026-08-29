class Project < ApplicationRecord
  has_many :agents, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_many :file_reservations, dependent: :destroy
  has_many :project_users, dependent: :delete_all
  has_many :users, through: :project_users
  has_many :attention_items, dependent: :nullify

  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase alphanumeric with dashes" }
  validates :path, presence: true, uniqueness: true
  validates :name, length: { maximum: 255 }, allow_blank: true
  validates :short_code,
            length: { maximum: 64 },
            format: { with: /\A[A-Za-z0-9_-]+\z/, message: "must use only letters, numbers, underscores, or dashes" },
            uniqueness: true,
            allow_blank: true

  before_validation :generate_slug_from_path, on: :create, if: -> { slug.blank? }
  before_validation :normalize_short_code
  after_create_commit :announce_creation

  def self.find_or_create_for_path(path)
    find_by(path: path) || create!(path: path)
  end

  def project_room
    rooms.find_by(type: "Rooms::Project")
  end

  def ensure_project_room!
    project_room || rooms.create!(
      type: "Rooms::Project",
      name: slug,
      private: private,
      creator: default_room_creator
    )
  end

  def display_name
    name.presence || slug
  end

  private

  def generate_slug_from_path
    self.slug = File.basename(path).parameterize
  end

  def normalize_short_code
    self.short_code = short_code.presence&.upcase
  end

  def default_room_creator
    User.where(role: :administrator).first || User.first
  end

  def announce_creation
    SystemMessage.project_created(project: self)
  end
end
