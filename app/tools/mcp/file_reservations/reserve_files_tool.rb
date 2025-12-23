module Mcp
  module FileReservations
    class ReserveFilesTool < Mcp::BaseTool
      description "Reserve file patterns to prevent edit conflicts with other agents"

      schema(
        properties: {
          patterns: { type: "array", items: { type: "string" }, description: "Glob patterns for files to reserve (e.g., 'app/models/**/*.rb')" },
          exclusive: { type: "boolean", description: "Whether reservation is exclusive (default true)" },
          reason: { type: "string", description: "Reason for the reservation" },
          ttl_seconds: { type: "integer", description: "Time to live in seconds (default 3600)" }
        },
        required: %w[patterns]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          patterns = params[:patterns]
          exclusive = params[:exclusive] != false
          reason = params[:reason]
          ttl_seconds = params[:ttl_seconds] || 3600

          project = agent.project

          # Check for conflicts with existing exclusive reservations
          if exclusive
            conflicts = project.file_reservations.active.exclusive
                              .where.not(agent_id: agent.id)
                              .select { |r| r.conflicts_with?(patterns) }

            if conflicts.any?
              # Broadcast conflict to project room
              conflicts.each do |conflict|
                SystemMessage.reservation_conflict(
                  room: project.project_room,
                  requester: agent,
                  holder: conflict.agent,
                  patterns: patterns
                )
              end

              return success_response({
                success: false,
                conflicts: conflicts.map do |c|
                  {
                    agent_id: c.agent_id,
                    agent_name: c.agent.name,
                    patterns: c.patterns,
                    expires_at: c.expires_at.iso8601
                  }
                end
              })
            end
          end

          reservation = project.file_reservations.create!(
            agent: agent,
            patterns: patterns,
            exclusive: exclusive,
            reason: reason,
            expires_at: Time.current + ttl_seconds.seconds
          )

          success_response({
            success: true,
            reservation_id: reservation.id,
            patterns: reservation.patterns,
            exclusive: reservation.exclusive,
            expires_at: reservation.expires_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
