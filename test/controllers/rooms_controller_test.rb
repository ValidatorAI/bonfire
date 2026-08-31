require "test_helper"

class RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "index redirects to the user's last room" do
    get rooms_url
    assert_redirected_to room_url(users(:david).rooms.last)
  end

  test "show" do
    get room_url(users(:david).rooms.last)
    assert_response :success
  end

  test "shows records the last room visited in a cookie" do
    get room_url(users(:david).rooms.last)
    assert response.cookies[:last_room] = users(:david).rooms.last.id
  end

  test "destroy" do
    assert_turbo_stream_broadcasts :rooms, count: 1 do
      assert_difference -> { Room.count }, -1 do
        delete room_url(rooms(:designers))
      end
    end
  end

  test "show renders child topic stream blocks when parent room has children" do
    parent_room = rooms(:designers)
    child_room = Rooms::Open.create_for({ name: "UI Refactor", creator: users(:david), parent: parent_room }, users: [ users(:david) ])
    child_room.messages.create!(body: "Refactoring the Zulip style stream", creator: users(:david))

    get room_url(parent_room)
    assert_response :success
    assert_select "##{ActionView::RecordIdentifier.dom_id(child_room, :topic_stream)}"
    assert_select ".topic-header-title", text: "💬 Topic: UI Refactor"
    assert_select ".topic-header-count", text: /1 message/
    assert_includes response.body, "Refactoring the Zulip style stream"
  end

  test "destroy only allowed for creators or those who can administer" do
    sign_in :jz

    assert_no_difference -> { Room.count } do
      delete room_url(rooms(:designers))
      assert_response :forbidden
    end

    rooms(:designers).update! creator: users(:jz)

    assert_difference -> { Room.count }, -1 do
      delete room_url(rooms(:designers))
    end
  end
end
