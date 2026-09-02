require "test_helper"

class Api::MessagesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_token = ENV["OUTPUT_EVENTS_TOKEN"]
    ENV["OUTPUT_EVENTS_TOKEN"] = "test-token"
    @project = Project.create!(path: "/tmp/api-messages-test", name: "Api Messages Test Project")
    @room = @project.rooms.create!(type: "Rooms::Project", name: "General", creator: users(:david))
    @message = @room.messages.create!(body: "Hello world", client_message_id: "api-msg-1", creator: users(:david))
  end

  teardown do
    ENV["OUTPUT_EVENTS_TOKEN"] = @previous_token
  end

  test "returns a single message with a valid token" do
    get api_project_room_message_url(@project.id, @room.id, @message.id), headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @message.id, body["id"]
    assert_equal "Hello world", body["body"]
  end

  test "rejects requests without a token" do
    get api_project_room_message_url(@project.id, @room.id, @message.id)

    assert_response :unauthorized
  end

  test "returns not found for an unknown message" do
    get api_project_room_message_url(@project.id, @room.id, -1), headers: { "Authorization" => "Bearer test-token" }

    assert_response :not_found
  end

  test "returns not found when message belongs to a different room" do
    other_room = @project.rooms.create!(type: "Rooms::Open", name: "Other", creator: users(:david))

    get api_project_room_message_url(@project.id, other_room.id, @message.id), headers: { "Authorization" => "Bearer test-token" }

    assert_response :not_found
  end

  test "returns all messages of a room with a valid token" do
    second_message = @room.messages.create!(body: "Second message", client_message_id: "api-msg-2", creator: users(:david))

    get api_project_room_messages_url(@project.id, @room.id), headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    ids = JSON.parse(response.body).map { |message| message["id"] }
    assert_equal [ @message.id, second_message.id ], ids
  end

  test "rejects index requests without a token" do
    get api_project_room_messages_url(@project.id, @room.id)

    assert_response :unauthorized
  end

  test "returns not found for index of an unknown room" do
    get api_project_room_messages_url(@project.id, -1), headers: { "Authorization" => "Bearer test-token" }

    assert_response :not_found
  end
end
