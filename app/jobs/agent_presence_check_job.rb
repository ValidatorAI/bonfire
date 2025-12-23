class AgentPresenceCheckJob < ApplicationJob
  queue_as :default

  def perform
    Agent.active.find_each do |agent|
      agent.check_presence!
    end
  end
end
