# db/seeds.rb
# Run with: bin/rails db:seed

puts "Setting up MCP Agent Chat..."

# This creates:
# - Account (singleton)
# - Human Overseer user (administrator)
# - "All Talk" main room
# - "Meta Events" room for system events
overseer = FirstRun.setup!

if overseer
  puts "  Created Human Overseer: #{overseer.name}"
  puts "  Created account: #{Account.first.name}"
  puts "  Created rooms:"
  Room.all.each { |r| puts "    - #{r.name} (#{r.class.name.demodulize})" }
else
  puts "  Already set up (Account exists)"
end

puts "Seeding demo attention items..."
sample_items = [
  {
    category: "decisions_waiting",
    title: "Approve liquidity pool smart contract audit",
    meta_text: "Requested by @Siavash • Due today",
    overdue: true,
    action_label: "Approve",
    target_type: "company_status"
  },
  {
    category: "decisions_waiting",
    title: "Confirm multi-sig threshold update policy",
    meta_text: "Requested by @Alex • 2 hours ago",
    overdue: false,
    action_label: "Confirm",
    target_type: "company_status"
  },
  {
    category: "blockers",
    title: "Carrier SMS sender registration is blocked",
    meta_text: "Owner waiting on your compliance handoff • 1 day blocked",
    overdue: true,
    action_label: "Assign & Unblock",
    target_type: "company_status"
  },
  {
    category: "outcomes_review",
    title: "Evaluate onboarding improvement outcome",
    meta_text: "Output shipped 2 weeks ago • Measure against 30% target",
    overdue: false,
    action_label: "Record Result",
    target_type: "company_status"
  },
  {
    category: "mentions",
    title: "@Siavash review design token migration plan",
    meta_text: "From # design-system • 48 minutes ago",
    overdue: false,
    action_label: "Mark Reviewed",
    target_type: "company_status"
  },
  {
    category: "material_changes",
    title: "Deployment architecture moved to Ubuntu Cockpit",
    meta_text: "Potential impact on release process • Confirm team readiness",
    overdue: false,
    action_label: "Acknowledge",
    target_type: "company_status"
  },
  {
    category: "ai_confirm",
    title: "Builder prepared deployment rollback routine",
    meta_text: "Needs human approval before execution",
    overdue: false,
    ai_confirm: true,
    action_label: "Approve Action",
    target_type: "company_status"
  },
  {
    category: "knowledge_proposals",
    title: "Approve benchmark playbook from ERC-4337 review",
    meta_text: "Proposed by @Researcher • linked to thread evidence",
    overdue: false,
    action_label: "Approve Knowledge",
    target_type: "company_status"
  }
]

sample_items.each do |attrs|
  AttentionItem.find_or_create_by!(category: attrs[:category], title: attrs[:title]) do |item|
    item.meta_text = attrs[:meta_text]
    item.overdue = attrs[:overdue]
    item.ai_confirm = attrs.fetch(:ai_confirm, false)
    item.action_label = attrs[:action_label]
    item.target_type = attrs[:target_type]
    item.status = :pending
  end
end

puts "Done!"
