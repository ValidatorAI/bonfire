Rails.application.config.mcp = ActiveSupport::OrderedOptions.new
Rails.application.config.mcp.allow_localhost_bypass = Rails.env.development?
Rails.application.config.mcp.rate_limit_requests_per_minute = 120
