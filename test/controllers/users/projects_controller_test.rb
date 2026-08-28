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
    assert Membership.exists?(room: project.project_room, participant: users(:david))
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
