require "test_helper"

class AttentionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in :david
    @attention_item = AttentionItem.create!(
      title: "Approve smart contract audit",
      category: "decisions_waiting",
      status: :pending
    )
  end

  test "resolves attention item via patch resolve" do
    patch resolve_attention_item_url(@attention_item), as: :json
    assert_response :success

    @attention_item.reload
    assert @attention_item.resolved?
    assert_equal users(:david), @attention_item.resolved_by
  end

  test "dismisses attention item via patch dismiss" do
    patch dismiss_attention_item_url(@attention_item), as: :json
    assert_response :success

    @attention_item.reload
    assert @attention_item.dismissed?
    assert_equal users(:david), @attention_item.resolved_by
  end

  test "resolves attention item via update status" do
    patch attention_item_url(@attention_item), params: { status: "resolved" }, as: :json
    assert_response :success

    @attention_item.reload
    assert @attention_item.resolved?
  end
end
