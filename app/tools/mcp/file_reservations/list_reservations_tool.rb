module Mcp
  module FileReservations
    class ListReservationsTool < Mcp::BaseTool
      description "List active file reservations in the project"

      schema(
        properties: {
          include_expired: { type: "boolean", description: "Include expired reservations" },
          agent_id: { type: "integer", description: "Filter by specific agent ID" }
        },
        required: []
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          include_expired = params[:include_expired] == true
          agent_filter = params[:agent_id]

          reservations = agent.project.file_reservations
          reservations = reservations.active unless include_expired
          reservations = reservations.where(agent_id: agent_filter) if agent_filter

          success_response({
            reservations: reservations.map do |r|
              {
                id: r.id,
                agent_id: r.agent_id,
                agent_name: r.agent.name,
                patterns: r.patterns,
                exclusive: r.exclusive,
                reason: r.reason,
                expired: r.expired?,
                expires_at: r.expires_at.iso8601,
                created_at: r.created_at.iso8601
              }
            end,
            total: reservations.count
          })
        end
      end
    end
  end
end
