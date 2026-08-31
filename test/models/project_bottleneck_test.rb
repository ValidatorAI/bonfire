require "test_helper"

class ProjectBottleneckTest < ActiveSupport::TestCase
  setup do
    @project = Project.create!(name: "Test Project", path: "/tmp/test-project-#{SecureRandom.hex(4)}")
  end

  test "validations" do
    bottleneck = @project.bottlenecks.build
    assert_not bottleneck.valid?
    assert_includes bottleneck.errors[:title], "can't be blank"

    bottleneck.title = "Obsidian Vault Indexing Timeout"
    assert bottleneck.valid?
  end

  test "active and resolved scopes and helpers" do
    active_item = @project.bottlenecks.create!(title: "Active bottleneck", severity: "active")
    resolved_item = @project.bottlenecks.create!(title: "Resolved bottleneck", severity: "resolved", resolved_at: Time.current)

    assert_includes @project.bottlenecks.active, active_item
    assert_not_includes @project.bottlenecks.active, resolved_item
    assert active_item.active?
    assert_not resolved_item.active?

    active_item.resolve!
    assert active_item.resolved_at.present?
    assert_equal "resolved", active_item.severity
  end
end
