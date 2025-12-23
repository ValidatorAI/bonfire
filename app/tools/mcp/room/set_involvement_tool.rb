module Mcp
  module Room
    class SetInvolvementTool < Mcp::BaseTool
      description "Set the involvement level for a room (everything, mentions, nothing)"

      schema(
        properties: {
          room_id: { type: "integer", description: "ID of the room" },
          involvement: { type: "string", enum: %w[everything mentions nothing], description: "Involvement level" }
        },
        required: %w[room_id involvement]
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          membership = agent.memberships.find_by(room_id: params[:room_id])
          return error_response("Not a member of this room", code: "forbidden") unless membership

          involvement = params[:involvement]
          unless %w[everything mentions nothing].include?(involvement)
            return error_response("Invalid involvement level", code: "validation_error")
          end

          membership.update!(involvement: involvement)

          success_response({
            room_id: membership.room_id,
            involvement: membership.involvement,
            updated_at: membership.updated_at.iso8601
          })
        rescue ActiveRecord::RecordInvalid => e
          error_response(e.message, code: "validation_error")
        end
      end
    end
  end
end
