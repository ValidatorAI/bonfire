require "test_helper"

class Users::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "new" do
    get user_company_project_new_url

    assert_response :success
    assert_match "Create Project", @response.body
    assert_match "General Details", @response.body
  end

  test "new lists only active non-bot users in human member picker" do
    deactivated_user = users(:jz)
    deactivated_user.update!(status: :deactivated)

    get user_company_project_new_url

    assert_response :success
    assert_match 'option value="' + users(:kevin).id.to_s + '"', @response.body
    assert_no_match(/<select id="project_member_user_picker"[^>]*>.*#{Regexp.escape(users(:bender).effective_display_name)}.*<\/select>/m, @response.body)
    assert_no_match deactivated_user.effective_display_name, @response.body
  end

  test "new renders only workspace allowed bots" do
    account = accounts(:signal)
    allowed_bot = users(:bender)
    disallowed_bot = User.create_bot!(
      name: "Ops Bot",
      display_name: "Ops Bot",
      email_address: "ops-bot-#{SecureRandom.hex(4)}@example.com"
    )

    account.update!(settings: account.settings_with_allowed_bot_user_ids([ allowed_bot.id ]))

    get user_company_project_new_url

    assert_response :success
    assert_match allowed_bot.effective_display_name, @response.body
    assert_no_match disallowed_bot.effective_display_name, @response.body
    assert_no_match "value=\"assistant\"", @response.body
  end

  test "new shows empty state when no workspace bots are allowed" do
    account = accounts(:signal)
    account.update!(settings: account.settings_with_allowed_bot_user_ids([]))

    get user_company_project_new_url

    assert_response :success
    assert_match "No workspace bots are allowed yet.", @response.body
    assert_no_match users(:bender).effective_display_name, @response.body
  end

  test "create creates project and redirects to overview" do
    assert_difference("Project.count", 1) do
      post user_company_projects_url, params: {
        project: {
          name: "Apollo Program",
          short_code: "APOLLO",
          description: "Moonshot planning and delivery",
          private: "1"
        }
      }
    end

    project = Project.order(:created_at).last

    assert_redirected_to user_company_project_overview_url(id: project.id)
    assert_equal "Apollo Program", project.name
    assert_equal "APOLLO", project.short_code
    assert project.private?
    assert_includes project.users, users(:david)
    assert project.project_room.present?
    assert project.project_room.private?
    assert Membership.exists?(room: project.project_room, participant: users(:david))

    channel_names = project.rooms.opens.where(parent_id: project.project_room.id).pluck(:name)
    assert_equal [ "releases", "specifications" ], channel_names.sort
  end

  test "create only creates selected default channels" do
    assert_difference("Project.count", 1) do
      post user_company_projects_url, params: {
        project: {
          name: "Project Skylab",
          short_code: "SKYLAB",
          description: "Orbital workshop"
        },
        default_channel_keys: [ "", "releases" ]
      }
    end

    project = Project.order(:created_at).last
    channel_names = project.rooms.opens.where(parent_id: project.project_room.id).pluck(:name)

    assert_equal [ "releases" ], channel_names
    assert_not project.private?
    assert_not project.project_room.private?
  end

  test "create adds selected human team members to project and project room" do
    selected_user = users(:kevin)

    assert_difference("Project.count", 1) do
      post user_company_projects_url, params: {
        project: {
          name: "Project Mercury",
          short_code: "MERC",
          description: "Crewed mission planning"
        },
        member_user_ids: [ users(:david).id.to_s, selected_user.id.to_s ]
      }
    end

    project = Project.order(:created_at).last

    assert_redirected_to user_company_project_overview_url(id: project.id)
    assert_includes project.users, users(:david)
    assert_includes project.users, selected_user
    assert Membership.exists?(room: project.project_room, participant: selected_user)
  end

  test "create broadcasts sidebar refresh for creator and selected members" do
    selected_user = users(:kevin)

    assert_difference("Project.count", 1) do
      post user_company_projects_url, params: {
        project: {
          name: "Project Orion",
          short_code: "ORION",
          description: "Deep-space coordination"
        },
        member_user_ids: [ users(:david).id.to_s, selected_user.id.to_s ]
      }
    end

    assert_redirected_to user_company_project_overview_url(id: Project.order(:created_at).last.id)

    [ users(:david), selected_user ].each do |user|
      target = ActionView::RecordIdentifier.dom_id(user, :sidebar_refresh)
      stream = send(:find_broadcasts_for, user, :rooms)

      assert_equal 1, stream.scan(%(target="#{target}")).count
      assert_match(/data-sidebar-refresh-trigger-value="true"/, stream)
    end
  end

  test "create ignores duplicate invalid inactive and bot member ids" do
    inactive_user = users(:jz)
    inactive_user.update!(status: :deactivated)

    assert_difference("Project.count", 1) do
      post user_company_projects_url, params: {
        project: {
          name: "Project Gemini",
          short_code: "GEM",
          description: "Docking tests"
        },
        member_user_ids: [
          users(:david).id.to_s,
          users(:kevin).id.to_s,
          users(:kevin).id.to_s,
          users(:bender).id.to_s,
          inactive_user.id.to_s,
          "999999",
          "bad-id"
        ]
      }
    end

    project = Project.order(:created_at).last

    assert_includes project.users, users(:david)
    assert_includes project.users, users(:kevin)
    assert_equal 1, project.project_users.where(user: users(:kevin)).count
    assert_not_includes project.users, users(:bender)
    assert_not_includes project.users, inactive_user
    assert Membership.exists?(room: project.project_room, participant: users(:kevin))
    assert_not Membership.exists?(room: project.project_room, participant: users(:bender))
    assert_not Membership.exists?(room: project.project_room, participant: inactive_user)
  end

  test "create with blank name returns unprocessable entity" do
    assert_no_difference("Project.count") do
      post user_company_projects_url, params: {
        project: {
          name: "",
          short_code: "BLANK",
          description: "Should fail"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_match "can&#39;t be blank", @response.body
  end

  test "overview" do
    project = create_project_for(users(:david))

    get user_company_project_overview_url(id: project.id)

    assert_response :success
    assert_match project.display_name, @response.body
    assert_match "Edit Project Details", @response.body
  end

  test "overview returns not found for non-member project" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get user_company_project_overview_url(id: -1)
    end
  end

  test "status" do
    project = create_project_for(users(:david))

    get user_company_project_status_url(id: project.id)

    assert_response :success
    assert_match project.display_name, @response.body
    assert_match "Project Status &amp; Alignment", @response.body
  end

  test "status returns not found for non-member project" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get user_company_project_status_url(id: -1)
    end
  end

  test "all hands" do
    project = create_project_for(users(:david))

    get user_company_project_all_hands_url(id: project.id)

    assert_response :success
    assert_match project.display_name, @response.body
    assert_match "All-Hands Hub", @response.body
  end

  test "all hands returns not found for non-member project" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get user_company_project_all_hands_url(id: -1)
    end
  end

  test "knowledge" do
    project = create_project_for(users(:david))

    get user_company_project_knowledge_url(id: project.id)

    assert_response :success
    assert_match project.display_name, @response.body
    assert_match "Knowledge Base", @response.body
  end

  test "knowledge returns not found for non-member project" do
    assert_raises(ActiveRecord::RecordNotFound) do
      get user_company_project_knowledge_url(id: -1)
    end
  end

  private
    def create_project_for(user)
      project = Project.create!(
        name: "Basecamp",
        path: "/tmp/basecamp-#{SecureRandom.hex(4)}",
        description: "Project fixture replacement"
      )

      project.project_users.create!(user: user)
      project.ensure_project_room!
      project
    end
end
