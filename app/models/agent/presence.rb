module Agent::Presence
  extend ActiveSupport::Concern

  IDLE_THRESHOLD = 5.minutes
  OFFLINE_THRESHOLD = 15.minutes

  included do
    scope :online, -> { where(status: :online) }
    scope :idle_agents, -> { where(status: :idle) }
    scope :offline, -> { where(status: :offline) }
  end

  def heartbeat!
    update!(status: :online, last_active_at: Time.current)
  end

  def mark_idle!
    update!(status: :idle)
  end

  def mark_offline!
    update!(status: :offline)
  end

  def check_presence!
    return if last_active_at.nil?

    if last_active_at < OFFLINE_THRESHOLD.ago
      mark_offline! unless offline?
    elsif last_active_at < IDLE_THRESHOLD.ago
      mark_idle! unless idle?
    end
  end

  def connected?
    online? || idle?
  end
end
