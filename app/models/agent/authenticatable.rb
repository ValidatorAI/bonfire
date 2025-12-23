module Agent::Authenticatable
  extend ActiveSupport::Concern

  class_methods do
    def authenticate_by_token(token)
      find_by(api_token: token)
    end
  end

  def regenerate_api_token!
    update!(api_token: SecureRandom.alphanumeric(24))
  end

  def api_key
    "agent-#{id}-#{api_token}"
  end
end
