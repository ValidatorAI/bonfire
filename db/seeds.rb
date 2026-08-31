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

puts "Seeding Company Status Periods and Items..."

august_period = CompanyStatusPeriod.find_or_create_by!(slug: "august-2026") do |period|
  period.name = "August 2026 (Current)"
  period.current = true
  period.starts_on = Date.new(2026, 8, 1)
  period.ends_on = Date.new(2026, 8, 31)
end

if august_period.company_status_items.empty?
  august_period.company_status_items.create!([
    {
      category: "priorities",
      position: 1,
      title: "1. Carevoo ERP MVP Launch",
      outcome: "Deploy core inventory and booking modules to beta salons by end of Q3.",
      detail_category: "Priority #1",
      description: "The primary milestone for Q3 is delivering the Minimum Viable Product (MVP) of Carevoo for beauty salon managers. The core release contains appointment scheduling, client management, and automated notification triggers.",
      owner: "Siavash (Lead Dev)",
      target_date: "Sept 30, 2026",
      status_label: "In Progress (68%)",
      impact: "Unlocks live user testing with initial 5 pilot salons and establishes real-world validation of our ClojureScript state management patterns.",
      actions: [
        "Finalize re-frame event handlers for multi-staff booking slots.",
        "Complete PostGIS spatial queries for nearby salon discovery.",
        "Conduct end-to-end user acceptance test with beta salon managers."
      ]
    },
    {
      category: "priorities",
      position: 2,
      title: "2. Infrastructure Stabilization",
      outcome: "Achieve zero-downtime deployments using current Ubuntu Cockpit configs.",
      detail_category: "Priority #2",
      description: "Transitioning server operations into an automated, GUI-visible system via Ubuntu Cockpit to monitor TLS certificates, service runtimes, and memory usage without manual SSH intervention.",
      owner: "Siavash",
      target_date: "Aug 28, 2026",
      status_label: "On Track",
      impact: "Ensures that infrastructure failures do not disrupt pilot users and reduces deployment time from 45 minutes to under 3 minutes.",
      actions: [
        "Automate certificate renewal checks within Cockpit.",
        "Script rollback routines in case of deployment failure."
      ]
    },
    {
      category: "priorities",
      position: 3,
      title: "3. Localized AI Integration",
      outcome: "Finalize local AI acceleration pipelines to reduce external API dependencies.",
      detail_category: "Priority #3",
      description: "Exporting localized generative AI pipelines using IREE and Vulkan runtimes to run directly on generalized AMD Radeon hardware, removing CUDA and paid cloud API lock-in.",
      owner: "AI R&D Team",
      target_date: "Mid Q4 2026",
      status_label: "Testing Phase",
      impact: "Cuts recurring cloud AI generation costs by ~90% for custom avatar and media processing.",
      actions: [
        "Benchmark Stable Diffusion export latency on Vulkan drivers.",
        "Test local GPU memory limits under concurrent load."
      ]
    },
    {
      category: "progress",
      position: 1,
      title: "Core UI Component Library (ClojureScript/re-frame)",
      percent: 85,
      color: "var(--accent-green, #10b981)",
      evidence: "All primary state subscriptions passing CI tests; forms rendering correctly in staging.",
      detail_category: "Progress Detail",
      description: "The core UI library provides reusable Reagent components powered by re-frame subscriptions. All forms, modals, tables, and navigational elements are standardizing on this structure.",
      owner: "Frontend Lead",
      target_date: "Aug 25, 2026",
      status_label: "85% Complete",
      impact: "Accelerates future feature development speed by 3x once all base atomic components are locked down.",
      actions: [
        "Polishing responsiveness on mobile screens.",
        "Finalizing accessible keyboard navigation across form controls."
      ]
    },
    {
      category: "progress",
      position: 2,
      title: "Automated SMS Pipeline",
      percent: 40,
      color: "var(--accent-yellow, #f59e0b)",
      evidence: "Backend gateway logic written, but waiting on external carrier verifications.",
      detail_category: "Progress Detail",
      description: "The SMS pipeline handles appointment reminders and registration confirmation codes sent directly to salon clients.",
      owner: "Backend Dev",
      target_date: "Pending Regulatory Clearance",
      status_label: "40% Complete (Blocked)",
      impact: "Crucial for salon client retention and reducing appointment no-shows.",
      actions: [
        "Maintain weekly check-ins with carrier registration support.",
        "Prepare fallback email template triggers."
      ]
    },
    {
      category: "risks",
      position: 1,
      title: "Carrier SMS Registration Delays",
      severity: "danger",
      icon: "🚨",
      description: "Carrier policies require extensive brand documentation before approving Alphanumeric Sender IDs and business registration bundles. Current review cycles are taking 4+ weeks with O2, Vodafone, and T-Mobile.",
      detail_category: "Critical Risk",
      owner: "Compliance / Ops",
      target_date: "Immediate",
      status_label: "Active Blocker",
      impact: "Outbound registration and appointment reminder texts risk being silently filtered by major cellular networks upon launch.",
      actions: [
        "Submitted updated registration forms directly to tier-1 aggregators.",
        "Evaluating temporary WhatsApp Business API integration as an emergency fallback."
      ]
    },
    {
      category: "risks",
      position: 2,
      title: "PostGIS Database Indexing",
      severity: "warning",
      icon: "⚠️",
      description: "Proximity calculations using SRID EPSG:4326 in PostGIS are hitting high latency spikes when executing spatial bounding-box checks over large datasets.",
      detail_category: "Technical Risk",
      owner: "Database Architect",
      target_date: "Sept 05, 2026",
      status_label: "Under Investigation",
      impact: "Could cause slow response times when salon clients search for nearby service providers.",
      actions: [
        "Implement spatial GIST indexes on coordinate columns.",
        "Benchmark radius search queries against cached bounding boxes."
      ]
    },
    {
      category: "dependencies",
      position: 1,
      title: "Carevoo Notification System → Compliance Review (Data Privacy)",
      from_name: "Carevoo Notification System",
      to_name: "Compliance Review (Data Privacy)",
      detail_category: "Cross-Project Dependency",
      description: "The customer notification engine requires strict ePrivacy and GDPR compliance validation regarding customer contact consent storage before sending live marketing messages.",
      owner: "Legal & Backend Lead",
      target_date: "Sept 10, 2026",
      status_label: "Pending Consent Audit",
      impact: "Prevents marketing automated campaigns from going live alongside the booking engine.",
      actions: [
        "Draft explicit opt-in checkbox components in customer-facing flows.",
        "Audit audit-log table schema for consent tracking."
      ]
    },
    {
      category: "changes",
      position: 1,
      title: "Pivoted primary deployment server architecture from raw Docker instances to utilizing Ubuntu Server via Cockpit.",
      detail_category: "Material Change",
      description: "We shifted from purely headless CLI Docker deployments to leveraging Ubuntu Server with Cockpit web services for server management.",
      owner: "DevOps",
      target_date: "Completed Aug 2026",
      status_label: "Implemented",
      impact: "Significantly reduces troubleshooting overhead for TLS handshake errors, memory leaks, and service logs.",
      actions: [
        "Configured hostname matching `.crt` SSL files in Cockpit.",
        "Created unified system administrative dashboard."
      ]
    },
    {
      category: "decisions",
      position: 1,
      title: "<strong>Frontend Framework:</strong> Standardized on ClojureScript with Reagent/re-frame.",
      detail_category: "Important Decision",
      description: "Chosen over standard React/TypeScript to guarantee strict immutability and centralized event routing across complex salon calendar screens.",
      owner: "Architecture Lead",
      target_date: "Locked In",
      status_label: "Active Standard",
      impact: "Eliminates state synchronization bugs across complex multi-paned interfaces.",
      actions: [
        "Document state subscription patterns in internal knowledge base.",
        "Maintain shadow-cljs build scripts."
      ]
    },
    {
      category: "learnings",
      position: 1,
      title: "<strong>Hardware Tooling:</strong> 500W spindles struggle with high-density materials compared to pulley-reduced 775 motors.",
      detail_category: "Key Learning",
      description: "Testing in our hardware lab showed 500W direct spindles stall under continuous load when milling aluminum brackets, whereas torque-reduced 775 motor setups maintain clean cutting speeds.",
      owner: "Hardware Lab",
      target_date: "N/A",
      status_label: "Applied to Prototypes",
      impact: "Saves hardware iteration cycles by establishing high-torque baselines for future physical enclosures.",
      actions: [
        "Update hardware component specs for all CNC milling builds.",
        "Order 3:1 pulley reduction gear sets."
      ]
    }
  ])
end

july_period = CompanyStatusPeriod.find_or_create_by!(slug: "july-2026") do |period|
  period.name = "July 2026"
  period.current = false
  period.starts_on = Date.new(2026, 7, 1)
  period.ends_on = Date.new(2026, 7, 31)
end

if july_period.company_status_items.empty?
  july_period.company_status_items.create!([
    {
      category: "priorities",
      position: 1,
      title: "1. Core Architecture Setup",
      outcome: "Establish base `project.clj` Leiningen configs for Carevoo.",
      detail_category: "July Milestone",
      description: "Initial foundational setup for the Carevoo repository using Clojure Leiningen project structures.",
      owner: "Siavash",
      target_date: "July 2026",
      status_label: "Completed",
      impact: "Established unified repo structure for frontend and backend.",
      actions: [ "Configured shadow-cljs and Leiningen aliases." ]
    }
  ])
end

june_period = CompanyStatusPeriod.find_or_create_by!(slug: "june-2026") do |period|
  period.name = "June 2026"
  period.current = false
  period.starts_on = Date.new(2026, 6, 1)
  period.ends_on = Date.new(2026, 6, 30)
end

if june_period.company_status_items.empty?
  june_period.company_status_items.create!([
    {
      category: "priorities",
      position: 1,
      title: "1. Feasibility & Mathematical Modeling",
      outcome: "Finalize matrix logic required for scheduling algorithms.",
      detail_category: "June Milestone",
      description: "Theoretical ground-level work using difference matrices over finite groups to design scheduling logic.",
      owner: "Siavash",
      target_date: "June 2026",
      status_label: "Completed",
      impact: "Validated mathematical feasibility for non-conflicting appointment slot generation.",
      actions: [ "Drafted thesis abstract and algorithm specs." ]
    }
  ])
end

puts "Seeding Demo Projects and Project Status..."

b2b_project = Project.find_or_create_by!(slug: "b2b-crypto-platform") do |project|
  project.name = "B2B Crypto Platform"
  project.path = "/projects/b2b-crypto-platform"
  project.short_code = "B2B"
  project.description = "B2B Crypto Platform is focused on secure institutional liquidity settlement with strong multi-signature governance and low-latency transaction confirmation workflows."
  project.current_phase = "Phase 2: Core Platform Development"
  project.progress_percent = 65
  project.recently_completed = "Tailwind CSS styling applied to profile settings and card-based booking selectors. Leaflet map integrations merged to main."
  project.private = false
end

b2b_project.update!(
  name: "B2B Crypto Platform",
  path: "/projects/b2b-crypto-platform",
  short_code: "B2B",
  description: "B2B Crypto Platform is focused on secure institutional liquidity settlement with strong multi-signature governance and low-latency transaction confirmation workflows.",
  current_phase: "Phase 2: Core Platform Development",
  progress_percent: 65,
  recently_completed: "Tailwind CSS styling applied to profile settings and card-based booking selectors. Leaflet map integrations merged to main."
)

user_to_assign = overseer || User.first
if user_to_assign
  b2b_project.project_users.find_or_create_by!(user: user_to_assign)
  project_room = b2b_project.ensure_project_room!
  Membership.find_or_create_by!(room: project_room, participant: user_to_assign)
end

if b2b_project.bottlenecks.empty?
  b2b_project.bottlenecks.create!([
    {
      title: "Obsidian Vault Indexing Timeout",
      description: "The Hermes agent is failing to scan larger directories when connected to the Obsidian Model Context Protocol server. We need to implement pagination or optimize the context window parsing.",
      severity: "active",
      position: 1
    }
  ])
end

if b2b_project.todos.empty?
  b2b_project.todos.create!([
    {
      title: "Finalize Express.js API Routes",
      meta_text: "Connect the Node.js backend to the newly merged frontend booking selectors.",
      completed: false,
      position: 1
    },
    {
      title: "Review Buzz Platform Workflows",
      meta_text: "Validate the latest decentralized agent workflows running on Block's Buzz project.",
      completed: false,
      position: 2
    }
  ])
end

if b2b_project.knowledge_items.empty?
  b2b_project.knowledge_items.create!([
    {
      title: "Infrastructure Routing",
      badge: "Architecture",
      description: "Our VPS is exclusively hosted on Infomaniak. Nginx Proxy Manager handles reverse proxy routing, and server administration is managed via Cockpit. Firewall rules have been updated to allow external binding.",
      position: 1
    },
    {
      title: "Custom Agent Delegation",
      badge: "AI Integration",
      description: "All queries regarding workspace documentation or generalized team knowledge should be @-mentioned to @orgknowledge in the relevant chatrooms, rather than querying external LLMs directly.",
      position: 2
    },
    {
      title: "Frontend Stack",
      badge: "Tech Stack",
      description: "The marketplace strictly adheres to vanilla JavaScript, HTML, and Tailwind CSS for mockups to ensure lightweight rendering before React/Vue integration.",
      position: 3
    }
  ])
end

if b2b_project.all_hands_meetings.empty?
  latest_meeting = b2b_project.all_hands_meetings.create!(
    title: "Latest: Q3 Kickoff & Security Review",
    held_at: Time.zone.parse("2026-08-17 10:00:00"),
    duration_minutes: 45,
    leader_name: "Sarah",
    notes: "Q3 alignment kickoff covering the core vault security audit results, target mainnet release schedule on September 15th, and liquidity provider outreach strategy.",
    position: 1
  )

  latest_meeting.takeaways.create!([
    {
      category: "Security",
      content: "The core vault logic passed the external audit with zero critical vulnerabilities.",
      position: 1
    },
    {
      category: "Timeline",
      content: "Leadership confirmed the Q3 launch target is locked in for September 15th.",
      position: 2
    },
    {
      category: "Marketing",
      content: "The go-to-market strategy is shifting slightly to focus on enterprise liquidity providers first.",
      position: 3
    }
  ])

  latest_meeting.action_items.create!([
    {
      title: "Finalize Multi-sig threshold logic",
      assignee_name: "Alex",
      due_date: "Aug 25",
      completed: false,
      position: 1
    },
    {
      title: "Draft release notes for V1",
      assignee_name: "Sarah",
      due_date: "Aug 28",
      completed: false,
      position: 2
    },
    {
      title: "Send Vault contract to auditors",
      assignee_name: "Siavash",
      completed: true,
      completed_at: Time.zone.parse("2026-08-18 14:00:00"),
      position: 3
    }
  ])

  latest_meeting.decisions.create!([
    {
      title: "We will use 3-of-5 multisig for mainnet deployment.",
      basis: "Decided in consensus",
      impact: "#smart-contracts",
      badge: "Logged in System",
      position: 1
    }
  ])

  b2b_project.all_hands_meetings.create!([
    {
      title: "Weekly Sync: Testing Phase 1",
      held_at: Time.zone.parse("2026-08-10 10:00:00"),
      duration_minutes: 30,
      leader_name: "Sarah",
      notes: "Discussed test coverage for vault smart contracts on testnet nodes and resolved state synchronization race conditions across multi-sig participants.",
      position: 2
    },
    {
      title: "Monthly Review: July Growth Metrics",
      held_at: Time.zone.parse("2026-08-03 10:00:00"),
      duration_minutes: 60,
      leader_name: "Alex",
      notes: "July retro and metric evaluation. Liquidity volumes grew by 24% month-over-month. Identified bottlenecks in client onboarding flow and API key generation.",
      position: 3
    }
  ])
end

puts "Done!"
