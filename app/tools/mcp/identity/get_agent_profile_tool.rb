module Mcp
  module Identity
    class GetAgentProfileTool < Mcp::BaseTool
      description "Get the current agent's profile information"

      schema(properties: {}, required: [])

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          success_response({
            id: agent.id,
            name: agent.name,
            program: agent.program,
            model: agent.model,
            task_description: agent.task_description,
            status: agent.status,
            project: {
              id: agent.project.id,
              slug: agent.project.slug,
              path: agent.project.path
            },
            rooms: agent.rooms.map { |r| { id: r.id, name: r.name, type: r.type } },
            file_reservations: agent.file_reservations.active.map do |r|
              { id: r.id, patterns: r.patterns, expires_at: r.expires_at.iso8601 }
            end,
            last_active_at: agent.last_active_at&.iso8601,
            created_at: agent.created_at.iso8601
          })
        end
      end
    end
  end
end
