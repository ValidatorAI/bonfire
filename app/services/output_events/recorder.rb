module OutputEvents
  class Recorder
    def self.record(event_type:, event_id: nil, actor: nil, target_type: nil, data: {})
      event = OutputEvent.create!(
        event_type: event_type,
        event_id: event_id,
        event_data: data.merge(
          "actor" => actor_data(actor),
          "target_type" => target_type,
          "occurred_at" => Time.current.iso8601
        ).compact
      )

      DeliverJob.perform_later(event.id)
      event
    end

    def self.actor_data(actor)
      return unless actor

      { "type" => actor.class.name, "id" => actor.id }
    end
    private_class_method :actor_data
  end
end