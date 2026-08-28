require "test_helper"

class Rooms::Projects::UsersSettingsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    @bot = users(:bender)
    @project = Project.create!(name: "Alpha", path: "/tmp/alpha")
    ProjectUser.create!(project: @project, user: users(:david))
    ProjectUser.create!(project: @project, user: @bot)
    accounts(:signal).update!(settings: accounts(:signal).settings_with_allowed_bot_user_ids([]))
  end

  test "show excludes globally disallowed bots from add teammate options" do
    get rooms_project_users_settings_url(@project)

    assert_response :ok
    assert_no_match "<option value=\"User:#{@bot.id}\"", response.body
  end

  test "update blocks forged add_agent for globally disallowed bot" do
    assert_no_difference -> { Membership.where(participant_type: "User", participant_id: @bot.id).count } do
      patch rooms_project_users_settings_url(@project), params: {
        intent: "add_agent",
        participant_id: "User:#{@bot.id}"
      }
    end

    assert_redirected_to rooms_project_users_settings_url(@project, refresh_project_settings: false)
  end
end
