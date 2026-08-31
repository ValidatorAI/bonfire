require "test_helper"

class ApprovalRequestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    @room = rooms(:designers)
    @message = messages(:first)
    @approval_request = ApprovalRequest.create!(
      room: @room,
      message: @message,
      request_type: "decision",
      payload: { "decision" => "Use gas optimization pattern for ERC-4337 router." },
      status: :pending
    )
  end

  test "confirms approval request via json" do
    patch confirm_approval_request_url(@approval_request), as: :json
    assert_response :success

    @approval_request.reload
    assert @approval_request.approved?
    assert_equal users(:david), @approval_request.resolved_by
  end

  test "approves approval request via turbo_stream" do
    patch approve_approval_request_url(@approval_request), as: :turbo_stream
    assert_response :success
    assert_includes response.body, %(id="approval_request_#{@approval_request.id}")

    @approval_request.reload
    assert @approval_request.approved?
  end

  test "denies approval request via json" do
    patch deny_approval_request_url(@approval_request), params: { note: "Not approved" }, as: :json
    assert_response :success

    @approval_request.reload
    assert @approval_request.denied?
  end

  test "cancels approval request via json" do
    patch cancel_approval_request_url(@approval_request), as: :json
    assert_response :success

    @approval_request.reload
    assert @approval_request.canceled?
  end

  test "shows approval request as json" do
    get approval_request_url(@approval_request), as: :json
    assert_response :success
    json = response.parsed_body
    assert_equal @approval_request.id, json["id"]
  end
end
