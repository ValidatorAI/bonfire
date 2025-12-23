class AgentMessagePoller
  POLL_TIMEOUT = 30.seconds
  POLL_INTERVAL = 0.5.seconds
  MAX_MESSAGES = 50

  def initialize(agent, rooms:, timeout: POLL_TIMEOUT)
    @agent = agent
    @rooms = rooms
    @timeout = timeout
    @start_time = Time.current
  end

  def wait_for_messages(since:)
    loop do
      messages = fetch_new_messages(since)
      return messages if messages.any?
      return [] if timed_out?
      sleep POLL_INTERVAL
    end
  end

  def poll_once(since:)
    fetch_new_messages(since)
  end

  private

  def fetch_new_messages(since)
    Message.where(room_id: @rooms.pluck(:id))
           .where("created_at > ?", since)
           .where.not(creator_type: "Agent", creator_id: @agent.id)
           .order(:created_at)
           .limit(MAX_MESSAGES)
  end

  def timed_out?
    Time.current - @start_time > @timeout
  end
end
