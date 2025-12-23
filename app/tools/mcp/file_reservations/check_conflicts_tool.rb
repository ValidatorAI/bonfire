module Mcp
  module FileReservations
    class CheckConflictsTool < Mcp::BaseTool
      description "Check if file patterns would conflict with existing reservations"

      schema(
        properties: {
          patterns: { type: "array", items: { type: "string" }, description: "Glob patterns to check for conflicts" }
        },
        required: %w[patterns]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          patterns = params[:patterns]

          conflicts = agent.project.file_reservations.active.exclusive
                          .where.not(agent_id: agent.id)
                          .select { |r| r.conflicts_with?(patterns) }

          success_response({
            has_conflicts: conflicts.any?,
            conflicts: conflicts.map do |c|
              {
                reservation_id: c.id,
                agent_id: c.agent_id,
                agent_name: c.agent.name,
                patterns: c.patterns,
                reason: c.reason,
                expires_at: c.expires_at.iso8601
              }
            end
          })
        end
      end
    end
  end
end
