module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      # Auto-identify as Human Overseer (same as web authentication)
      self.current_user = FirstRun.human_overseer
    end
  end
end
