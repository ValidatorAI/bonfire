module Mcp
  module FileReservations
    class ReleaseReservationTool < Mcp::BaseTool
      description "Release a file reservation"

      schema(
        properties: {
          reservation_id: { type: "integer", description: "ID of the reservation to release" }
        },
        required: %w[reservation_id]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          reservation = agent.file_reservations.find_by(id: params[:reservation_id])
          return error_response("Reservation not found", code: "not_found") unless reservation

          patterns = reservation.patterns
          reservation.destroy!

          success_response({
            released: true,
            patterns: patterns
          })
        end
      end
    end
  end
end
