module Mcp
  class SetupController < ApplicationController
    skip_before_action :verify_authenticity_token
    skip_before_action :require_authenticated_user, raise: false

    def index
      render json: {
        instructions: instructions_url
      }
    end

    def instructions
      instructions_path = Rails.root.join("docs/MCP_AGENT_INSTRUCTIONS.md")

      unless File.exist?(instructions_path)
        return render plain: "Instructions not found", status: :not_found
      end

      send_file instructions_path,
        type: "text/markdown",
        disposition: "inline",
        filename: "MCP_AGENT_INSTRUCTIONS.md"
    end

    private

    def instructions_url
      "#{request.base_url}/mcp/setup/instructions"
    end
  end
end
