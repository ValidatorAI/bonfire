class Room < ApplicationRecord
  belongs_to :project, optional: true

  after_create_commit :announce_creation, unless: :skip_announcement?
  after_create_commit :auto_join_human_overseer

  has_many :memberships, dependent: :delete_all do
    def grant_to(participants)
      room = proxy_association.owner
      Array(participants).each do |participant|
        Membership.find_or_create_by!(
          room_id: room.id,
          participant_type: participant.class.name,
          participant_id: participant.id
        ) do |m|
          m.involvement = room.default_involvement
        end
      end
    end

    def revoke_from(participants)
      Array(participants).each do |participant|
        where(participant_type: participant.class.name, participant_id: participant.id).destroy_all
      end
    end

    def revise(granted: [], revoked: [])
      transaction do
        grant_to(granted) if granted.present?
        revoke_from(revoked) if revoked.present?
      end
    end
  end

  # Separate associations for users and agents
  has_many :user_memberships, -> { where(participant_type: "User") }, class_name: "Membership"
  has_many :agent_memberships, -> { where(participant_type: "Agent") }, class_name: "Membership"
  has_many :users, through: :user_memberships, source: :participant, source_type: "User"
  has_many :agents, through: :agent_memberships, source: :participant, source_type: "Agent"

  has_many :messages, dependent: :destroy

  belongs_to :creator, class_name: "User", default: -> { Current.user }

  scope :opens,           -> { where(type: "Rooms::Open") }
  scope :closeds,         -> { where(type: "Rooms::Closed") }
  scope :directs,         -> { where(type: "Rooms::Direct") }
  scope :projects,        -> { where(type: "Rooms::Project") }
  scope :tasks,           -> { where(type: "Rooms::Task") }
  scope :without_directs, -> { where.not(type: "Rooms::Direct") }
  scope :active,          -> { where(archived_at: nil) }
  scope :archived,        -> { where.not(archived_at: nil) }

  scope :ordered, -> { order("LOWER(name)") }

  class << self
    def create_for(attributes, users:)
      transaction do
        create!(attributes).tap do |room|
          room.memberships.grant_to users
        end
      end
    end

    def original
      order(:created_at).first
    end
  end

  def receive(message)
    unread_memberships(message)
    push_later(message)
  end

  def open?
    is_a?(Rooms::Open)
  end

  def closed?
    is_a?(Rooms::Closed)
  end

  def direct?
    is_a?(Rooms::Direct)
  end

  def project_room?
    is_a?(Rooms::Project)
  end

  def task_room?
    is_a?(Rooms::Task)
  end

  def archived?
    archived_at.present?
  end

  def archive!
    update!(archived_at: Time.current)
  end

  def unarchive!
    update!(archived_at: nil)
  end

  def default_involvement
    "mentions"
  end

  # Get all participants (users + agents)
  def participants
    memberships.includes(:participant).map(&:participant)
  end

  private
    def unread_memberships(message)
      memberships.visible.disconnected
                 .where.not(participant_type: message.creator_type, participant_id: message.creator_id)
                 .update_all(unread_at: message.created_at, updated_at: Time.current)
    end

    def push_later(message)
      Room::PushMessageJob.perform_later(self, message)
    end

    def announce_creation
      SystemMessage.room_created(room: self, creator: creator)
    end

    def skip_announcement?
      # Don't announce meta room creation (would cause infinite loop)
      # Don't announce during initial setup
      is_a?(Rooms::Meta) || !Rooms::Meta.any?
    end

    def auto_join_human_overseer
      overseer = User.find_by(email_address: FirstRun::HUMAN_OVERSEER_EMAIL)
      return unless overseer

      memberships.grant_to(overseer) unless users.include?(overseer)
    end
end
