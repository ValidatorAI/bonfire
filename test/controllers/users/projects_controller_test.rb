require "test_helper"

class Users::ProjectsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "overview" do
    project = projects(:basecamp)

    get user_company_project_overview_url(id: project.id)

    assert_response :success
    assert_match project.display_name, @response.body
    assert_match "Edit Project Details", @response.body
  end

  test "overview returns not found for non-member project" do
    get user_company_project_overview_url(id: -1)

    assert_response :not_found
  end

  test "status" do
    project = projects(:basecamp)

    get user_company_project_status_url(id: project.id)

    assert_response :success
    assert_match project.display_name, @response.body
    assert_match "Project Status &amp; Alignment", @response.body
  end

  test "status returns not found for non-member project" do
    get user_company_project_status_url(id: -1)

    assert_response :not_found
  end

  test "all hands" do
    project = projects(:basecamp)

    get user_company_project_all_hands_url(id: project.id)

    assert_response :success
    assert_match project.display_name, @response.body
    assert_match "All-Hands Hub", @response.body
  end

  test "all hands returns not found for non-member project" do
    get user_company_project_all_hands_url(id: -1)

    assert_response :not_found
  end
end
