require "test_helper"

class Accounts::UsersControllerTest < ActionDispatch::IntegrationTest
  test "update" do
    sign_in :david
    assert users(:david).administrator?

    put account_user_url(users(:david)), params: { user: { role: "administrator" } }

    assert_redirected_to edit_account_url
    assert users(:david).reload.administrator?
  end

  test "update redirects back to company settings when requested" do
    sign_in :david
    put account_user_url(users(:david)), params: { user: { role: "member" }, return_to: "company_settings" }

    assert_redirected_to user_company_settings_url(user_id: "me")
    assert users(:david).reload.member?
  end

  test "create" do
    sign_in :david
    assert_difference -> { User.count }, 1 do
      post account_users_url, params: { user: { name: "New User", email_address: "new.user@example.com", password: "secret123456" } }
    end

    assert_redirected_to edit_account_url
    assert_equal "New User", User.order(:id).last.name
  end

  test "destroy" do
    sign_in :david
    assert_difference -> { User.active.count }, -1 do
      delete account_user_url(users(:david))
    end

    assert_redirected_to edit_account_url
    assert_nil User.active.find_by(id: users(:david).id)
  end

  test "destroy redirects back to company settings when requested" do
    sign_in :david
    delete account_user_url(users(:david)), params: { return_to: "company_settings" }

    assert_redirected_to user_company_settings_url(user_id: "me")
    assert users(:david).reload.deactivated?
  end

  test "activate" do
    sign_in :david
    users(:kevin).update!(status: :deactivated)

    patch activate_account_user_url(users(:kevin)), params: { return_to: "company_settings" }

    assert_redirected_to user_company_settings_url(user_id: "me")
    assert users(:kevin).reload.active?
  end

  test "cannot update or change status for bot users" do
    sign_in :david
    assert_raises ActiveRecord::RecordNotFound do
      put account_user_url(users(:bender)), params: { user: { role: "member" }, return_to: "company_settings" }
    end

    assert_raises ActiveRecord::RecordNotFound do
      delete account_user_url(users(:bender)), params: { return_to: "company_settings" }
    end

    assert_raises ActiveRecord::RecordNotFound do
      patch activate_account_user_url(users(:bender)), params: { return_to: "company_settings" }
    end
  end

  test "non-admins cannot perform actions" do
    users(:david).update!(role: :member)
    sign_in :david

    put account_user_url(users(:kevin)), params: { user: { role: "administrator" } }
    assert_response :forbidden

    delete account_user_url(users(:kevin))
    assert_response :forbidden

    patch activate_account_user_url(users(:kevin))
    assert_response :forbidden
  end
end
