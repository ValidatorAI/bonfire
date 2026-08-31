class FirstRun
  ACCOUNT_NAME = "Bonfire"
  FIRST_ROOM_NAME = "All Talk"
  META_ROOM_NAME = "Meta Events"
  HUMAN_OVERSEER_NAME = "Human Overseer"
  HUMAN_OVERSEER_EMAIL = "overseer@bonfire.local"
  HUMAN_OVERSEER_PASSWORD = "PavelLab"

  class << self
    # Auto-setup without user input - creates Human Overseer automatically
    def setup!
      return if Account.any?

      ActiveRecord::Base.transaction do
        Account.create!(name: ACCOUNT_NAME)

        # Create Human Overseer - the single human user
        overseer = User.create!(
          name: HUMAN_OVERSEER_NAME,
          email_address: HUMAN_OVERSEER_EMAIL,
          role: :administrator,
          password: HUMAN_OVERSEER_PASSWORD
        )

        overseer
      end
    end

    def human_overseer
      overseer = User.find_by(email_address: HUMAN_OVERSEER_EMAIL) || setup!
      ensure_overseer_in_all_rooms(overseer) if overseer
      overseer
    end

    def ensure_overseer_in_all_rooms(overseer)
      Room.find_each do |room|
        # Check specifically for User membership (not Agent with same id)
        next if Membership.exists?(
          room_id: room.id,
          participant_type: "User",
          participant_id: overseer.id
        )

        Membership.create(
          room_id: room.id,
          participant_type: "User",
          participant_id: overseer.id,
          involvement: room.default_involvement
        )
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound
        # Already exists, ignore
      end
    end

    # Legacy method for compatibility
    def create!(user_params)
      setup!
    end
  end
end
