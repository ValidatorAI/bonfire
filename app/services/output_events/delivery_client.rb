require "net/http"
require "uri"

module OutputEvents
  class DeliveryClient
    ENDPOINT_TIMEOUT = 7.seconds

    class PermanentDeliveryError < StandardError; end
    class TransientDeliveryError < StandardError; end

    def deliver(event)
      response = http(uri).request(request(event))
      return if response.is_a?(Net::HTTPSuccess)

      error_class = response.code.to_i >= 500 ? TransientDeliveryError : PermanentDeliveryError
      raise error_class, "Output event delivery returned HTTP #{response.code}"
    rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNREFUSED, Errno::ECONNRESET => error
      raise TransientDeliveryError, error.message
    end

    private
      def uri
        @uri ||= URI(ENV.fetch("OUTPUT_EVENTS_URL"))
      end

      def http(destination)
        Net::HTTP.new(destination.host, destination.port).tap do |connection|
          connection.use_ssl = destination.scheme == "https"
          connection.open_timeout = ENDPOINT_TIMEOUT
          connection.read_timeout = ENDPOINT_TIMEOUT
        end
      end

      def request(event)
        Net::HTTP::Post.new(uri, headers).tap do |post|
          post.body = payload(event).to_json
        end
      end

      def headers
        { "Content-Type" => "application/json" }.tap do |headers|
          token = ENV["OUTPUT_EVENTS_TOKEN"].presence
          headers["Authorization"] = "Bearer #{token}" if token
        end
      end

      def payload(event)
        {
          id: event.id,
          event_type: event.event_type,
          event_id: event.event_id,
          event_data: event.event_data,
          created_at: event.created_at.iso8601
        }
      end
  end
end