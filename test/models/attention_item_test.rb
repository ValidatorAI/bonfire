require "test_helper"

class AttentionItemTest < ActiveSupport::TestCase
  test "validates category and title" do
    item = AttentionItem.new(title: "Check system", category: "decisions_waiting")
    assert item.valid?

    item.title = ""
    assert_not item.valid?

    item.title = "Valid title"
    item.category = "invalid_category"
    assert_not item.valid?
  end

  test "resolves item with user" do
    user = users(:david)
    item = AttentionItem.create!(
      title: "Confirm multi-sig threshold update",
      category: "decisions_waiting",
      status: :pending
    )

    assert item.pending?
    assert_nil item.resolved_at

    item.resolve!(user)

    assert item.resolved?
    assert_equal user, item.resolved_by
    assert_not_nil item.resolved_at
  end

  test "dismisses item" do
    user = users(:david)
    item = AttentionItem.create!(
      title: "Review doc",
      category: "mentions",
      status: :pending
    )

    item.dismiss!(user)

    assert item.dismissed?
    assert_equal user, item.resolved_by
  end

  test "scopes filter by open, overdue, and user" do
    user = users(:david)
    other_user = users(:jason)

    open_item = AttentionItem.create!(
      title: "Open item for all",
      category: "decisions_waiting",
      status: :pending,
      overdue: true
    )
    user_item = AttentionItem.create!(
      title: "User item",
      category: "blockers",
      user: user,
      status: :pending
    )
    other_item = AttentionItem.create!(
      title: "Other user item",
      category: "blockers",
      user: other_user,
      status: :pending
    )

    user_items = AttentionItem.for_user(user).open_items
    assert_includes user_items, open_item
    assert_includes user_items, user_item
    assert_not_includes user_items, other_item

    overdue_items = AttentionItem.overdue_items
    assert_includes overdue_items, open_item
    assert_not_includes overdue_items, user_item
  end

  test "effective_action_label returns default or custom label" do
    item_default = AttentionItem.new(title: "Test", category: "decisions_waiting")
    assert_equal "Approve", item_default.effective_action_label

    item_custom = AttentionItem.new(title: "Test", category: "decisions_waiting", action_label: "Custom Action")
    assert_equal "Custom Action", item_custom.effective_action_label
  end
end
