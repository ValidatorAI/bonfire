class WellKnownController < ActionController::API
  # Respond to OAuth discovery probes indicating no auth required
  # Claude Code's MCP client probes these before connecting

  def oauth_protected_resource
    # Return empty authorization_servers to signal no OAuth needed
    render json: {
      resource: request.base_url,
      authorization_servers: []
    }
  end

  def not_implemented
    # Return 404 with JSON body (Claude Code expects JSON even for errors)
    render json: { error: "not_found", error_description: "This server does not require OAuth authentication" }, status: :not_found
  end
end
