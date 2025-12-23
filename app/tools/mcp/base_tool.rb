module Mcp
  class BaseTool
    class << self
      def tool_name
        name.demodulize.underscore.sub(/_tool$/, "")
      end

      def tool_description
        @description || "No description provided"
      end

      def description(text)
        @description = text
      end

      def input_schema
        @input_schema || { type: "object", properties: {}, required: [] }
      end

      def schema(properties:, required: [])
        @input_schema = {
          type: "object",
          properties: properties,
          required: required
        }
      end

      def call(params)
        raise NotImplementedError, "Subclasses must implement .call"
      end

      protected

      def current_agent(params)
        params[:server_context]&.dig(:agent)
      end

      def success_response(data)
        {
          content: [
            { type: "text", text: data.to_json }
          ]
        }
      end

      def error_response(message, code: "error")
        {
          content: [
            { type: "text", text: { error: code, message: message }.to_json }
          ],
          isError: true
        }
      end
    end
  end
end
