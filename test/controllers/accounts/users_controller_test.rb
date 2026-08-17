require "test_helper"

class Accounts::UsersControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
  end

  test "update" do
    assert users(:david).administrator?

    put account_user_url(users(:david)), params: { user: { role: "administrator" } }

    assert_redirected_to edit_account_url
    assert users(:david).reload.administrator?
  end

  test "create" do
    assert_difference -> { User.count }, 1 do
      post account_users_url, params: { user: { name: "New User", email_address: "new.user@example.com", password: "secret123456" } }
    end

    assert_redirected_to edit_account_url
    assert_equal "New User", User.order(:id).last.name
  end

  test "destroy" do
    assert_difference -> { User.active.count }, -1 do
      delete account_user_url(users(:david))
    end

    assert_redirected_to edit_account_url
    assert_nil User.active.find_by(id: users(:david).id)
  end

  test "non-admins cannot perform actions" do
    sign_in :kevin

    post account_users_url, params: { user: { name: "Blocked", email_address: "blocked@example.com", password: "secret123456" } }
    assert_response :forbidden

    put account_user_url(users(:david)), params: { user: { role: "administrator" } }
    assert_response :forbidden

    delete account_user_url(users(:david))
    assert_response :forbidden
  end
end
