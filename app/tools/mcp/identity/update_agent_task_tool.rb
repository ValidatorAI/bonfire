module Mcp
  module Identity
    class UpdateAgentTaskTool < Mcp::BaseTool
      description "Update the current task description for the agent"

      schema(
        properties: {
          task_description: { type: "string", description: "New task description" }
        },
        required: %w[task_description]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          agent.update!(task_description: params[:task_description])

          success_response({
            agent_name: agent.name,
            task_description: agent.task_description,
            updated_at: agent.updated_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
