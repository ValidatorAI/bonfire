module Mcp
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :identify_agent
      skip_before_action :verify_authenticity_token, raise: false
    end

    private

    # Agents self-identify - no token validation required
    # Priority: Session ID > Agent ID header > Name header > Bearer token > IP fallback
    def identify_agent
      @current_agent = find_agent_by_session || find_agent_by_id || find_agent_by_name || find_agent_by_token || find_agent_by_ip

      # Allow unauthenticated requests for registration and handshake
      return if @current_agent || registration_request?

      render_unauthorized
    end

    # Look up agent by MCP session ID (stored on agent during macro_start_session)
    def find_agent_by_session
      return unless mcp_session_id.present?
      Agent.find_by(mcp_session_id: mcp_session_id)
    end

    def find_agent_by_id
      return unless agent_id_header.present?
      Agent.find_by(id: agent_id_header)
    end

    def find_agent_by_name
      return unless agent_name_header.present? && project_slug_header.present?
      project = Project.find_by(slug: project_slug_header)
      project&.agents&.find_by(name: agent_name_header)
    end

    def find_agent_by_token
      return unless bearer_token.present?
      Agent.authenticate_by_token(bearer_token)
    end

    # Fallback: find the most recently active agent from localhost
    # This enables native MCP clients that can't send custom headers after registration
    def find_agent_by_ip
      # Only works for local connections (security measure)
      return unless request.remote_ip.in?(%w[127.0.0.1 ::1 localhost])

      # Find the most recently active online agent
      Agent.where(status: "online")
           .where("last_active_at > ?", 10.minutes.ago)
           .order(last_active_at: :desc)
           .first
    end

    def mcp_session_id
      request.headers["Mcp-Session-Id"]
    end

    def agent_id_header
      request.headers["X-Agent-Id"]
    end

    def agent_name_header
      request.headers["X-Agent-Name"]
    end

    def project_slug_header
      request.headers["X-Project-Slug"]
    end

    def bearer_token
      request.headers["Authorization"]&.sub(/\ABearer\s+/, "")
    end

    def registration_request?
      return false unless request.body.present?

      body = request.body.read
      request.body.rewind

      begin
        parsed = JSON.parse(body)
        method = parsed["method"]
        tool_name = parsed.dig("params", "name")

        # Allow MCP protocol handshake methods without auth
        return true if method.in?(%w[initialize notifications/initialized tools/list resources/list prompts/list])

        # Allow registration tools without auth
        return true if method == "tools/call" && tool_name.in?(%w[register_agent macro_start_session ping])

        false
      rescue JSON::ParserError
        false
      end
    end

    def render_unauthorized
      render json: {
        jsonrpc: "2.0",
        error: { code: -32000, message: "Unauthorized - provide X-Agent-Id or X-Agent-Name + X-Project-Slug headers" },
        id: nil
      }, status: :unauthorized
    end

    def current_agent
      @current_agent
    end
  end
end
