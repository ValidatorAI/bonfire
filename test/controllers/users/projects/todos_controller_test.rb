require "test_helper"

class Users::Projects::TodosControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    @project = Project.create!(
      name: "B2B Crypto Platform",
      path: "/tmp/b2b-crypto-#{SecureRandom.hex(4)}",
      description: "Platform specs"
    )
    @project.project_users.create!(user: users(:david))
    @todo = @project.todos.create!(title: "Finalize Express.js API Routes", meta_text: "Connect backend to frontend", completed: false)
  end

  test "toggle updates todo to completed with turbo stream" do
    patch user_company_project_todo_toggle_url(project_id: @project.id, id: @todo.id), as: :turbo_stream

    assert_response :success
    assert_match %(turbo-stream action="replace"), @response.body
    assert_match "Finalize Express.js API Routes", @response.body
    assert @todo.reload.completed?
  end

  test "toggle updates todo to completed with html redirect" do
    patch user_company_project_todo_toggle_url(project_id: @project.id, id: @todo.id)

    assert_redirected_to user_company_project_status_url(id: @project.id)
    assert @todo.reload.completed?
  end

  test "toggle returns not found for non-member user" do
    other_user = users(:kevin)
    sign_in other_user

    assert_raises(ActiveRecord::RecordNotFound) do
      patch user_company_project_todo_toggle_url(project_id: @project.id, id: @todo.id)
    end
  end
end
