module Mcp
  module Identity
    class ListAgentsTool < Mcp::BaseTool
      description "List all agents in the current project"

      schema(
        properties: {
          status: { type: "string", enum: %w[online offline idle all], description: "Filter by status" },
          include_self: { type: "boolean", description: "Include the requesting agent" }
        },
        required: []
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          status_filter = params[:status] || "all"
          include_self = params[:include_self] != false

          agents = agent.project.agents.ordered
          agents = agents.where.not(id: agent.id) unless include_self

          case status_filter
          when "online"
            agents = agents.online
          when "offline"
            agents = agents.offline
          when "idle"
            agents = agents.idle
          end

          success_response({
            agents: agents.map do |a|
              {
                id: a.id,
                name: a.name,
                program: a.program,
                model: a.model,
                status: a.status,
                task_description: a.task_description,
                last_active_at: a.last_active_at&.iso8601
              }
            end,
            total: agents.count
          })
        end
      end
    end
  end
end
