module Mcp
  module Authentication
    extend ActiveSupport::Concern

    included do
      before_action :identify_agent
      skip_before_action :verify_authenticity_token, raise: false
    end

    private

    # Agents must identify via MCP session header or API token
    # Priority: Session ID (Mcp-Session-Id header) > Bearer token
    def identify_agent
      @current_agent = find_agent_by_session || find_agent_by_token

      # Allow unauthenticated requests for registration and handshake
      return if @current_agent || registration_request?

      render_unauthorized
    end

    # Look up agent by MCP session ID (stored on agent during macro_start_session)
    def find_agent_by_session
      return unless mcp_session_id.present?
      Agent.find_by(mcp_session_id: mcp_session_id)
    end

    def find_agent_by_token
      return unless bearer_token.present?
      Agent.authenticate_by_token(bearer_token)
    end

    def mcp_session_id
      request.headers["Mcp-Session-Id"]
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
        error: { code: -32000, message: "Unauthorized - include Authorization: Bearer <api_token> or Mcp-Session-Id header" },
        id: nil
      }, status: :unauthorized
    end

    def current_agent
      @current_agent
    end
  end
end
