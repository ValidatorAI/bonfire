module Mcp
  module Identity
    class UpdateAgentStatusTool < Mcp::BaseTool
      description "Update the current agent's presence status (online, idle, or offline)"

      schema(
        properties: {
          status: {
            type: "string",
            description: "New status value",
            enum: Agent.statuses.keys
          }
        },
        required: %w[status]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          status = params[:status].to_s
          return error_response("Invalid status", code: "validation_error") unless Agent.statuses.key?(status)

          agent.update!(status: status, last_active_at: Time.current)

          success_response({
            status: agent.status,
            last_active_at: agent.last_active_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
