class Rooms::Meta < Room
  # Meta room for system events: agent join/leave, room creation, file reservations, etc.
  # There should only be one meta room per installation.

  validates :name, presence: true

  def default_involvement
    "everything"
  end

  class << self
    def instance
      first || create_default!
    end

    private

    def create_default!
      overseer = FirstRun.human_overseer
      create!(name: FirstRun::META_ROOM_NAME, creator: overseer).tap do |room|
        room.memberships.grant_to(overseer)
      end
    end
  end
end
