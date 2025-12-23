module Mcp
  module ErrorHandling
    extend ActiveSupport::Concern

    included do
      rescue_from StandardError, with: :handle_internal_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActionController::ParameterMissing, with: :handle_bad_request
    end

    private

    def handle_internal_error(exception)
      Rails.logger.error("[MCP Error] #{exception.class}: #{exception.message}")
      Rails.logger.error(exception.backtrace.first(10).join("\n"))

      render json: {
        jsonrpc: "2.0",
        error: {
          code: -32603,
          message: "Internal error",
          data: { request_id: request.uuid }
        },
        id: parsed_request_id
      }, status: :internal_server_error
    end

    def handle_not_found(exception)
      render json: {
        jsonrpc: "2.0",
        error: {
          code: -32602,
          message: exception.message
        },
        id: parsed_request_id
      }, status: :ok
    end

    def handle_bad_request(exception)
      render json: {
        jsonrpc: "2.0",
        error: {
          code: -32600,
          message: "Invalid request: #{exception.message}"
        },
        id: parsed_request_id
      }, status: :ok
    end

    def parsed_request_id
      @parsed_request_id ||= begin
        JSON.parse(request.body.read)["id"]
      rescue StandardError
        nil
      ensure
        request.body.rewind
      end
    end
  end
end
