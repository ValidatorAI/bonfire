module Mcp
  module Identity
    class ListBotsTool < Mcp::BaseTool
      description "List chat bots"

      schema(
        properties: {
          include_deactivated: { type: "boolean", description: "Include deactivated bots" },
          include_webhook_url: { type: "boolean", description: "Include webhook URL when available" }
        },
        required: []
      )

      class << self
        def call(params)
          agent = current_agent(params)
          return error_response("Not authenticated", code: "unauthorized") unless agent

          include_deactivated = params[:include_deactivated] == true
          include_webhook_url = params[:include_webhook_url] != false

          bots = if include_deactivated
            User.where(role: :bot)
          else
            User.active_bots
          end

          bots = bots.ordered.includes(:webhook)

          success_response({
            bots: bots.map { |bot| serialize_bot(bot, include_webhook_url: include_webhook_url) },
            total: bots.count
          })
        end

        private

        def serialize_bot(bot, include_webhook_url:)
          data = {
            id: bot.id,
            name: bot.name,
            email_address: bot.email_address,
            status: bot.status,
            created_at: bot.created_at&.iso8601,
            updated_at: bot.updated_at&.iso8601
          }

          data[:webhook_url] = bot.webhook_url if include_webhook_url
          data
        end
      end
    end
  end
end