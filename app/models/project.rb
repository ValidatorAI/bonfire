class Project < ApplicationRecord
  has_many :agents, dependent: :destroy
  has_many :rooms, dependent: :destroy
  has_many :file_reservations, dependent: :destroy

  validates :slug, presence: true, uniqueness: true,
            format: { with: /\A[a-z0-9\-]+\z/, message: "must be lowercase alphanumeric with dashes" }
  validates :path, presence: true, uniqueness: true

  before_validation :generate_slug_from_path, on: :create, if: -> { slug.blank? }
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
      creator: default_room_creator
    )
  end

  private

  def generate_slug_from_path
    self.slug = File.basename(path).parameterize
  end

  def default_room_creator
    User.where(role: :administrator).first || User.first
  end

  def announce_creation
    SystemMessage.project_created(project: self)
  end
end
