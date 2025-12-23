module Mcp
  module Workflow
    class HeartbeatTool < Mcp::BaseTool
      description "Send a heartbeat to maintain online presence and optionally renew file reservations"

      schema(
        properties: {
          renew_reservations: { type: "boolean", description: "Also renew all active file reservations" },
          task_description: { type: "string", description: "Optionally update task description" }
        },
        required: []
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          renew_reservations = params[:renew_reservations] == true
          task_description = params[:task_description]

          # Update presence
          agent.heartbeat!

          # Update task if provided
          agent.update!(task_description: task_description) if task_description.present?

          # Renew reservations if requested
          renewed_reservations = []
          if renew_reservations
            agent.file_reservations.active.each do |r|
              r.renew!(ttl_seconds: 3600)
              renewed_reservations << {
                id: r.id,
                patterns: r.patterns,
                expires_at: r.expires_at.iso8601
              }
            end
          end

          success_response({
            status: agent.status,
            last_active_at: agent.last_active_at.iso8601,
            task_description: agent.task_description,
            renewed_reservations: renewed_reservations
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
