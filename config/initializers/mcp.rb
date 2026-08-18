Rails.application.config.mcp = ActiveSupport::OrderedOptions.new
Rails.application.config.mcp.allow_localhost_bypass = Rails.env.development?
Rails.application.config.mcp.rate_limit_requests_per_minute = 120
Rails.application.config.mcp.poll_default_timeout_seconds = ENV.fetch("MCP_POLL_DEFAULT_TIMEOUT_SECONDS", 15).to_i
Rails.application.config.mcp.poll_max_timeout_seconds = ENV.fetch("MCP_POLL_MAX_TIMEOUT_SECONDS", 30).to_i
Rails.application.config.mcp.poll_interval_seconds = ENV.fetch("MCP_POLL_INTERVAL_SECONDS", 0.25).to_f
Rails.application.config.mcp.tool_timeout_seconds = ENV.fetch("MCP_TOOL_TIMEOUT_SECONDS", 20).to_i
