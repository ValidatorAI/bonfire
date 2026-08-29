require "test_helper"

class Users::CompaniesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "home renders attention inbox and signals" do
    AttentionItem.create!(
      title: "Approve smart contract audit",
      category: "decisions_waiting",
      status: :pending,
      overdue: true
    )

    get user_company_home_url(user_id: "me")

    assert_response :ok
    assert_select "h2", "What needs your attention?"
    assert_select "[data-home-attention-target='openCount']", text: "1"
    assert_select "[data-home-attention-target='overdueCount']", text: "1"
    assert_select ".home-attention-card", count: 7
    assert_select ".list-item-title", text: "Approve smart contract audit"
  end

  test "status renders company direction dashboard and month selector" do
    get user_company_status_url(user_id: "me")

    assert_response :ok
    assert_select "h1", "Shared Direction & Status"
    assert_select "select#company-month-selector" do
      assert_select "option[value='august-2026']"
      assert_select "option[value='july-2026']"
      assert_select "option[value='june-2026']"
    end
    assert_select "[data-controller~='company-status']"
    assert_select ".company-card-title", text: /Current Priorities/
    assert_select ".company-card-title", text: /Progress Supported by Evidence/
    assert_select ".company-card-title", text: /Risks & Blockers/
    assert_select ".company-card-title", text: /Cross-Project Dependencies/
    assert_select ".company-card-title", text: /Material Changes/
    assert_select ".company-card-title", text: /Important Decisions/
    assert_select ".company-card-title", text: /Learning That Changed Future Work/
    assert_select "#company-detail-drawer"
  end

  test "settings" do
    get user_company_settings_url(user_id: "me")

    assert_response :ok
    assert_select "section[aria-label='Global AI integrations']"
    assert_select "section[aria-label='Organization profile'] input[type='file'][name='account[logo]']"
  end

  test "admin can open add user modal" do
    get user_company_add_user_url(user_id: "me")

    assert_response :ok
    assert_select "h1", "Add User"
    assert_select "form[action='#{account_users_path}']"
  end

  test "non admin cannot see organization avatar upload" do
    sign_in :kevin

    get user_company_settings_url(user_id: "me")

    assert_response :ok
    assert_select "section[aria-label='Organization profile'] input[type='file'][name='account[logo]']", count: 0
  end

  test "non admin cannot open add user modal" do
    sign_in :kevin

    get user_company_add_user_url(user_id: "me")

    assert_response :forbidden
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
