require "test_helper"

class OutputEvents::RecorderTest < ActiveSupport::TestCase
  test "persists an unsynced event and enqueues delivery" do
    actor = users(:david)
    group_id = SecureRandom.uuid

    assert_enqueued_with(job: OutputEvents::DeliverJob) do
      event = OutputEvents::Recorder.record(
        event_type: "message_created",
        event_id: 42,
        group_id: group_id,
        actor: actor,
        target_type: "Message",
        data: { "room_id" => 5 }
      )

      assert_not event.synced?
      assert_equal 42, event.event_id
      assert_equal group_id, event.group_id
      assert_equal "Message", event.event_data["target_type"]
      assert_equal({ "type" => "User", "id" => actor.id }, event.event_data["actor"])
    end
  end
end