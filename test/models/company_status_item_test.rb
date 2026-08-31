require "test_helper"

class CompanyStatusItemTest < ActiveSupport::TestCase
  setup do
    @period = CompanyStatusPeriod.create!(slug: "period-sample", name: "Sample Period")
  end

  test "validates category inclusion" do
    item = @period.company_status_items.build(category: "invalid_category", title: "Some title")
    assert_not item.valid?

    item.category = "priorities"
    assert item.valid?
  end

  test "formats as_status_payload with detail context" do
    item = @period.company_status_items.create!(
      category: "progress",
      title: "Core UI",
      percent: 85,
      color: "#10b981",
      evidence: "Passing CI",
      description: "Reagent components",
      owner: "Frontend Lead",
      target_date: "Aug 25, 2026",
      status_label: "85% Complete",
      impact: "Accelerates velocity",
      actions: [ "Mobile polish" ]
    )

    payload = item.as_status_payload

    assert_equal "Core UI", payload[:title]
    assert_equal "Core UI", payload[:label]
    assert_equal "85", payload[:percent]
    assert_equal "#10b981", payload[:color]
    assert_equal "Passing CI", payload[:evidence]
    assert_equal "Progress", payload[:details][:category]
    assert_equal "Frontend Lead", payload[:details][:owner]
    assert_equal "85% Complete", payload[:details][:status]
    assert_equal [ "Mobile polish" ], payload[:details][:actions]
  end
end
