require "test_helper"

class Users::CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "settings" do
    get user_company_settings_url(user_id: "me")

    assert_response :ok
    assert_select "section[aria-label='Global AI integrations']"
    assert_select "section[aria-label='Organization profile'] input[type='file'][name='account[logo]']"
  end

  test "non admin cannot see organization avatar upload" do
    sign_in :kevin

    get user_company_settings_url(user_id: "me")

    assert_response :ok
    assert_select "section[aria-label='Organization profile'] input[type='file'][name='account[logo]']", count: 0
  end

  test "admin can update allowed bots and deselect removes from all rooms and projects" do
    bot = users(:bender)
    account = accounts(:signal)

    project = Project.create!(name: "Ops", path: "/tmp/ops")
    ProjectUser.create!(project: project, user: users(:david))
    ProjectUser.create!(project: project, user: bot)

    room = Room.create!(name: "Ops Room", type: "Rooms::Closed", creator: users(:david), project: project)
    room.memberships.grant_to([ users(:david), bot ])

    account.update!(settings: account.settings_with_allowed_bot_user_ids([ bot.id ]))

    assert ProjectUser.where(project: project, user: bot).exists?
    assert Membership.where(participant_type: "User", participant_id: bot.id).exists?

    patch user_update_company_settings_url(user_id: "me"), params: {
      account: {
        settings: {
          allowed_bot_user_ids: [ "" ]
        }
      }
    }

    assert_redirected_to user_company_settings_url(user_id: "me")
    assert_equal [], account.reload.allowed_bot_user_ids
    assert_not ProjectUser.where(project: project, user: bot).exists?
    assert_not Membership.where(participant_type: "User", participant_id: bot.id).exists?
  end

  test "non admin cannot update company bot settings" do
    sign_in :kevin

    patch user_update_company_settings_url(user_id: "me"), params: {
      account: {
        settings: {
          allowed_bot_user_ids: [ users(:bender).id.to_s ]
        }
      }
    }

    assert_response :forbidden
  end
end
