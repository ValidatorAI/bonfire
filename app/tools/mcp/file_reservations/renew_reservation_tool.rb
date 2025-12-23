module Mcp
  module FileReservations
    class RenewReservationTool < Mcp::BaseTool
      description "Renew a file reservation to extend its expiry time"

      schema(
        properties: {
          reservation_id: { type: "integer", description: "ID of the reservation to renew" },
          ttl_seconds: { type: "integer", description: "New time to live in seconds (default 3600)" }
        },
        required: %w[reservation_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          reservation = agent.file_reservations.find_by(id: params[:reservation_id])
          return error_response("Reservation not found", code: "not_found") unless reservation

          ttl_seconds = params[:ttl_seconds] || 3600
          reservation.renew!(ttl_seconds: ttl_seconds)

          success_response({
            reservation_id: reservation.id,
            patterns: reservation.patterns,
            expires_at: reservation.expires_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
