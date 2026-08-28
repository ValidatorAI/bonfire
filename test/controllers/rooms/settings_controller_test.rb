require "test_helper"

class Rooms::SettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    @bot = users(:bender)
    @project = Project.create!(name: "Beta", path: "/tmp/beta")
    ProjectUser.create!(project: @project, user: users(:david))
    ProjectUser.create!(project: @project, user: @bot)
    @room = Room.create!(name: "Beta Room", type: "Rooms::Closed", creator: users(:david), project: @project)
    @room.memberships.grant_to(users(:david))
    accounts(:signal).update!(settings: accounts(:signal).settings_with_allowed_bot_user_ids([]))
  end

  test "show excludes globally disallowed bots from add teammate options" do
    get room_settings_url(@room)

    assert_response :ok
    assert_no_match "User:#{@bot.id}", response.body
  end

  test "update blocks forged add_agent for globally disallowed bot" do
    assert_no_difference -> { Membership.where(room: @room, participant_type: "User", participant_id: @bot.id).count } do
      patch room_settings_url(@room), params: {
        intent: "add_agent",
        participant_id: "User:#{@bot.id}"
      }
    end

    assert_redirected_to room_settings_url(@room)
  end
end
