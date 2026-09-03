require "test_helper"

class Api::AttentionItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @previous_token = ENV["OUTPUT_EVENTS_TOKEN"]
    ENV["OUTPUT_EVENTS_TOKEN"] = "test-token"
    @project = Project.create!(path: "/tmp/api-attention-items-test", name: "Api Attention Items Test Project")
    @room = @project.rooms.create!(type: "Rooms::Project", name: "General", creator: users(:david))
    @attention_item = AttentionItem.create!(
      title: "Decision needed for API rollout",
      category: "decisions_waiting",
      status: :pending,
      user: users(:david),
      project: @project,
      room: @room,
      due_at: 1.day.from_now
    )
  end

  teardown do
    ENV["OUTPUT_EVENTS_TOKEN"] = @previous_token
  end

  test "returns all attention items with a valid token" do
    second_item = AttentionItem.create!(
      title: "Follow up on launch review",
      category: "mentions",
      status: :pending,
      user: users(:jason),
      project: @project,
      room: @room,
      due_at: 2.days.from_now
    )

    get api_attention_items_url, headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body["count"]
    assert_equal [ @attention_item.id, second_item.id ].sort, body["attention_items"].map { |item| item["id"] }.sort
  end

  test "paginates attention items when a page param is given" do
    second_item = AttentionItem.create!(
      title: "Follow up on launch review",
      category: "mentions",
      status: :pending,
      user: users(:jason),
      project: @project,
      room: @room,
      due_at: 2.days.from_now
    )

    get api_attention_items_url(page: 1, per_page: 1), headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal 2, body["count"]
    assert_equal 1, body["page"]
    assert_equal 1, body["per_page"]
    assert_equal [ @attention_item.id ], body["attention_items"].map { |item| item["id"] }

    get api_attention_items_url(page: 2, per_page: 1), headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    assert_equal [ second_item.id ], JSON.parse(response.body)["attention_items"].map { |item| item["id"] }
  end

  test "returns an attention item with a valid token" do
    get api_attention_item_url(@attention_item.id), headers: { "Authorization" => "Bearer test-token" }

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal @attention_item.id, body["id"]
    assert_equal @attention_item.category, body["category"]
    assert_equal @attention_item.title, body["title"]
  end

  test "rejects requests without a token" do
    get api_attention_item_url(@attention_item.id)

    assert_response :unauthorized
  end

  test "rejects requests with an invalid token" do
    get api_attention_item_url(@attention_item.id), headers: { "Authorization" => "Bearer wrong-token" }

    assert_response :unauthorized
  end

  test "returns not found for an unknown attention item" do
    get api_attention_item_url(-1), headers: { "Authorization" => "Bearer test-token" }

    assert_response :not_found
  end
end
