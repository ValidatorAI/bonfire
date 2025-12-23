module Mcp
  class SetupController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_authenticated_user, raise: false

    SCRIPTS = {
      "register_agent.sh" => "scripts/mcp/register_agent.sh",
      "agent-chat.sh" => "scripts/mcp/agent-chat.sh",
      "check_reservation.sh" => "scripts/mcp/check_reservation.sh",
      "cleanup_session.sh" => "scripts/mcp/cleanup_session.sh"
    }.freeze

    def show
      script_name = params[:script_name]

      unless SCRIPTS.key?(script_name)
        return render plain: "Unknown script: #{script_name}", status: :not_found
      end

      script_path = Rails.root.join(SCRIPTS[script_name])

      unless File.exist?(script_path)
        return render plain: "Script not found: #{script_name}", status: :not_found
      end

      send_file script_path,
        type: "text/plain",
        disposition: "inline",
        filename: script_name
    end

    def index
      render json: {
        available_scripts: SCRIPTS.keys,
        guide: "#{request.base_url}/mcp/setup/guide",
        usage: "curl -o <script_name> #{request.base_url}/mcp/setup/<script_name>"
      }
    end

    def guide
      guide_path = Rails.root.join("docs/agent-setup-package/AGENT_SETUP.md")

      unless File.exist?(guide_path)
        return render plain: "Guide not found", status: :not_found
      end

      send_file guide_path,
        type: "text/plain",
        disposition: "inline",
        filename: "AGENT_SETUP.md"
    end
  end
end
