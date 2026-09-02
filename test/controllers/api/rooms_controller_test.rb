require "test_helper"

class Api::RoomsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_token = ENV["OUTPUT_EVENTS_TOKEN"]
    ENV["OUTPUT_EVENTS_TOKEN"] = "test-token"
    @project = Project.create!(path: "/tmp/api-rooms-test", name: "Api Rooms Test Project")
    @room = @project.rooms.create!(type: "Rooms::Project", name: "General", creator: users(:david))
  end

  teardown do
    ENV["OUTPUT_EVENTS_TOKEN"] = @previous_token
  end

  test "returns rooms for a project with a valid token" do
    get api_project_rooms_url(@project.id), headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_includes body.map { |room| room["id"] }, @room.id
  end

  test "returns rooms for a project looked up by slug" do
    get api_project_rooms_url(@project.slug), headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    assert_includes JSON.parse(response.body).map { |room| room["id"] }, @room.id
  end

  test "rejects requests without a token" do
    get api_project_rooms_url(@project.id)

    assert_response :unauthorized
  end

  test "returns not found for an unknown project" do
    get api_project_rooms_url("does-not-exist"), headers: { "Authorization" => "Bearer test-token" }

    assert_response :not_found
  end
end
