module Mcp
  class JsonRpcServer
    PARSE_ERROR = -32700
    INVALID_REQUEST = -32600
    METHOD_NOT_FOUND = -32601
    INVALID_PARAMS = -32602
    INTERNAL_ERROR = -32603
    SERVER_ERROR = -32000

    attr_reader :tools, :context

    def initialize(tools:, context: {})
      @tools = tools.index_by(&:tool_name)
      @context = context
    end

    def handle(json_string)
      request = parse_request(json_string)
      return request if request.is_a?(Hash) && request[:error]

      process_request(request)
    rescue StandardError => e
      Rails.logger.error("[MCP] Unexpected error: #{e.message}")
      Rails.logger.error(e.backtrace.first(10).join("\n"))
      error_response(INTERNAL_ERROR, "Internal error", nil)
    end

    private

    def parse_request(json_string)
      JSON.parse(json_string, symbolize_names: true)
    rescue JSON::ParserError => e
      error_response(PARSE_ERROR, "Parse error: #{e.message}", nil)
    end

    def process_request(request)
      id = request[:id]
      method = request[:method]
      params = request[:params] || {}

      return error_response(INVALID_REQUEST, "Invalid request: missing method", id) unless method

      # Handle MCP protocol methods
      case method
      when "initialize"
        handle_initialize(id, params)
      when "notifications/initialized"
        handle_notifications_initialized(id, params)
      when "tools/list"
        handle_tools_list(id)
      when "tools/call"
        handle_tools_call(id, params)
      when "resources/list"
        handle_resources_list(id)
      when "prompts/list"
        handle_prompts_list(id)
      when "ping"
        success_response(id, {})
      else
        error_response(METHOD_NOT_FOUND, "Method not found: #{method}", id)
      end
    end

    def handle_initialize(id, params)
      # Negotiate protocol version - prefer 2025-03-26, fallback to 2024-11-05
      client_version = params[:protocolVersion] || "2024-11-05"
      server_version = client_version.start_with?("2025") ? "2025-03-26" : "2024-11-05"

      success_response(id, {
        protocolVersion: server_version,
        capabilities: {
          tools: {}
        },
        serverInfo: {
          name: "campfire-mcp",
          version: "1.0.0"
        }
      })
    end

    def handle_notifications_initialized(id, params)
      # Client confirms initialization complete - just acknowledge
      # This is a notification (no response expected), but we return success if id present
      id ? success_response(id, {}) : nil
    end

    def handle_resources_list(id)
      # We don't have resources, return empty list
      success_response(id, { resources: [] })
    end

    def handle_prompts_list(id)
      # We don't have prompts, return empty list
      success_response(id, { prompts: [] })
    end

    def handle_tools_list(id)
      tool_list = tools.values.map do |tool|
        {
          name: tool.tool_name,
          description: tool.tool_description,
          inputSchema: tool.input_schema
        }
      end

      success_response(id, { tools: tool_list })
    end

    def handle_tools_call(id, params)
      tool_name = params[:name]
      arguments = params[:arguments] || {}

      tool = tools[tool_name]
      return error_response(METHOD_NOT_FOUND, "Tool not found: #{tool_name}", id) unless tool

      begin
        result = tool.call(arguments.merge(server_context: context))
        success_response(id, result)
      rescue ArgumentError => e
        error_response(INVALID_PARAMS, e.message, id)
      rescue ActiveRecord::RecordNotFound => e
        error_response(SERVER_ERROR, "Not found: #{e.message}", id)
      rescue ActiveRecord::RecordInvalid => e
        error_response(SERVER_ERROR, "Validation error: #{e.message}", id)
      rescue StandardError => e
        Rails.logger.error("[MCP] Tool error: #{e.message}")
        error_response(INTERNAL_ERROR, e.message, id)
      end
    end

    def success_response(id, result)
      {
        jsonrpc: "2.0",
        id: id,
        result: result
      }
    end

    def error_response(code, message, id)
      {
        jsonrpc: "2.0",
        id: id,
        error: {
          code: code,
          message: message
        }
      }
    end
  end
end
