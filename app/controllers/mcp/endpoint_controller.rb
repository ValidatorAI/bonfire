module Mcp
  class EndpointController < BaseController
    skip_before_action :identify_agent, only: %i[health handle_get]

    # POST /mcp - Main JSON-RPC endpoint (Streamable HTTP transport)
    def handle
      body = request.body.read
      parsed = JSON.parse(body) rescue {}

      # Check if this is a notification (no id field) - return 202 Accepted with empty body
      if notification_request?(parsed)
        return head :accepted
      end

      session_id = request.headers["Mcp-Session-Id"]

      server = Mcp::JsonRpcServer.new(
        tools: Mcp::ToolRegistry.all,
        context: { agent: current_agent, request_id: request.uuid, mcp_session_id: session_id }
      )

      result = server.handle(body)

      # Check if this is an initialize request - if so, include session header
      if parsed["method"] == "initialize"
        response.headers["Mcp-Session-Id"] = generate_session_id
      end

      # Return JSON response (we don't use SSE streaming currently)
      response.headers["Content-Type"] = "application/json"
      render json: result
    end

    # GET /mcp - SSE stream endpoint (Streamable HTTP transport)
    # We don't support server-initiated messages, so just return empty
    def handle_get
      # Check Accept header
      unless request.headers["Accept"]&.include?("text/event-stream")
        return render json: { error: "Accept header must include text/event-stream" }, status: :not_acceptable
      end

      response.headers["Content-Type"] = "text/event-stream"
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Connection"] = "keep-alive"

      # Send an empty SSE stream that immediately closes
      # (we don't have server-initiated messages to push)
      render plain: ""
    end

    # DELETE /mcp - Session termination (Streamable HTTP transport)
    def handle_delete
      # We don't track sessions server-side, so just acknowledge
      head :no_content
    end

    def health
      render json: {
        status: "ok",
        version: "1.0.0",
        protocolVersion: "2025-03-26",
        timestamp: Time.current.iso8601
      }
    end

    private

    def notification_request?(parsed)
      # JSON-RPC notifications have a method but no id field
      parsed.is_a?(Hash) && parsed["method"].present? && !parsed.key?("id")
    end

    def generate_session_id
      # Generate a unique session ID for this connection
      SecureRandom.uuid
    end
  end
end
