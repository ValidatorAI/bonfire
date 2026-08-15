module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :signed_in?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end

    def allow_bot_access(**options)
      allow_unauthenticated_access(**options)
      before_action :require_bot_authentication, **options
    end
  end

  private
    def signed_in?
      Current.user.present?
    end

    def require_authentication
      # Auto-identify as Human Overseer - no login required
      # This ensures the account and overseer user exist
      Current.user = FirstRun.human_overseer
    end

    def require_bot_authentication
      Current.user = User.authenticate_bot(params[:bot_key])
      head :not_found unless Current.user
    end
end
