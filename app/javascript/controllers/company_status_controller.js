import { Controller } from "@hotwired/stimulus"

const COMPANY_STATUS_DATA = {
  "august-2026": {
    priorities: [
      {
        id: "p1",
        title: "1. Carevoo ERP MVP Launch",
        outcome: "Deploy core inventory and booking modules to beta salons by end of Q3.",
        details: {
          category: "Priority #1",
          description: "The primary milestone for Q3 is delivering the Minimum Viable Product (MVP) of Carevoo for beauty salon managers. The core release contains appointment scheduling, client management, and automated notification triggers.",
          owner: "Siavash (Lead Dev)",
          targetDate: "Sept 30, 2026",
          status: "In Progress (68%)",
          impact: "Unlocks live user testing with initial 5 pilot salons and establishes real-world validation of our ClojureScript state management patterns.",
          actions: [
            "Finalize re-frame event handlers for multi-staff booking slots.",
            "Complete PostGIS spatial queries for nearby salon discovery.",
            "Conduct end-to-end user acceptance test with beta salon managers."
          ]
        }
      },
      {
        id: "p2",
        title: "2. Infrastructure Stabilization",
        outcome: "Achieve zero-downtime deployments using current Ubuntu Cockpit configs.",
        details: {
          category: "Priority #2",
          description: "Transitioning server operations into an automated, GUI-visible system via Ubuntu Cockpit to monitor TLS certificates, service runtimes, and memory usage without manual SSH intervention.",
          owner: "Siavash",
          targetDate: "Aug 28, 2026",
          status: "On Track",
          impact: "Ensures that infrastructure failures do not disrupt pilot users and reduces deployment time from 45 minutes to under 3 minutes.",
          actions: [
            "Automate certificate renewal checks within Cockpit.",
            "Script rollback routines in case of deployment failure."
          ]
        }
      },
      {
        id: "p3",
        title: "3. Localized AI Integration",
        outcome: "Finalize local AI acceleration pipelines to reduce external API dependencies.",
        details: {
          category: "Priority #3",
          description: "Exporting localized generative AI pipelines using IREE and Vulkan runtimes to run directly on generalized AMD Radeon hardware, removing CUDA and paid cloud API lock-in.",
          owner: "AI R&D Team",
          targetDate: "Mid Q4 2026",
          status: "Testing Phase",
          impact: "Cuts recurring cloud AI generation costs by ~90% for custom avatar and media processing.",
          actions: [
            "Benchmark Stable Diffusion export latency on Vulkan drivers.",
            "Test local GPU memory limits under concurrent load."
          ]
        }
      }
    ],
    progress: [
      {
        id: "pr1",
        label: "Core UI Component Library (ClojureScript/re-frame)",
        percent: "85",
        color: "var(--accent-green, #10b981)",
        evidence: "All primary state subscriptions passing CI tests; forms rendering correctly in staging.",
        details: {
          category: "Progress Detail",
          description: "The core UI library provides reusable Reagent components powered by re-frame subscriptions. All forms, modals, tables, and navigational elements are standardizing on this structure.",
          owner: "Frontend Lead",
          targetDate: "Aug 25, 2026",
          status: "85% Complete",
          impact: "Accelerates future feature development speed by 3x once all base atomic components are locked down.",
          actions: [
            "Polishing responsiveness on mobile screens.",
            "Finalizing accessible keyboard navigation across form controls."
          ]
        }
      },
      {
        id: "pr2",
        label: "Automated SMS Pipeline",
        percent: "40",
        color: "var(--accent-yellow, #f59e0b)",
        evidence: "Backend gateway logic written, but waiting on external carrier verifications.",
        details: {
          category: "Progress Detail",
          description: "The SMS pipeline handles appointment reminders and registration confirmation codes sent directly to salon clients.",
          owner: "Backend Dev",
          targetDate: "Pending Regulatory Clearance",
          status: "40% Complete (Blocked)",
          impact: "Crucial for salon client retention and reducing appointment no-shows.",
          actions: [
            "Maintain weekly check-ins with carrier registration support.",
            "Prepare fallback email template triggers."
          ]
        }
      }
    ],
    risks: [
      {
        id: "r1",
        type: "danger",
        icon: "🚨",
        title: "Carrier SMS Registration Delays",
        desc: "Alphanumeric sender ID for Carevoo is stuck in review with T-Mobile and Vodafone.",
        details: {
          category: "Critical Risk",
          description: "Carrier policies require extensive brand documentation before approving Alphanumeric Sender IDs and business registration bundles. Current review cycles are taking 4+ weeks with O2, Vodafone, and T-Mobile.",
          owner: "Compliance / Ops",
          targetDate: "Immediate",
          status: "Active Blocker",
          impact: "Outbound registration and appointment reminder texts risk being silently filtered by major cellular networks upon launch.",
          actions: [
            "Submitted updated registration forms directly to tier-1 aggregators.",
            "Evaluating temporary WhatsApp Business API integration as an emergency fallback."
          ]
        }
      },
      {
        id: "r2",
        type: "warning",
        icon: "⚠️",
        title: "PostGIS Database Indexing",
        desc: "Geographic data queries for salon proximity running slower than expected in staging.",
        details: {
          category: "Technical Risk",
          description: "Proximity calculations using SRID EPSG:4326 in PostGIS are hitting high latency spikes when executing spatial bounding-box checks over large datasets.",
          owner: "Database Architect",
          targetDate: "Sept 05, 2026",
          status: "Under Investigation",
          impact: "Could cause slow response times when salon clients search for nearby service providers.",
          actions: [
            "Implement spatial GIST indexes on coordinate columns.",
            "Benchmark radius search queries against cached bounding boxes."
          ]
        }
      }
    ],
    dependencies: [
      {
        id: "d1",
        from: "Carevoo Notification System",
        to: "Compliance Review (Data Privacy)",
        details: {
          category: "Cross-Project Dependency",
          description: "The customer notification engine requires strict ePrivacy and GDPR compliance validation regarding customer contact consent storage before sending live marketing messages.",
          owner: "Legal & Backend Lead",
          targetDate: "Sept 10, 2026",
          status: "Pending Consent Audit",
          impact: "Prevents marketing automated campaigns from going live alongside the booking engine.",
          actions: [
            "Draft explicit opt-in checkbox components in customer-facing flows.",
            "Audit audit-log table schema for consent tracking."
          ]
        }
      }
    ],
    changes: [
      {
        id: "c1",
        text: "Pivoted primary deployment server architecture from raw Docker instances to utilizing Ubuntu Server via Cockpit.",
        details: {
          category: "Material Change",
          description: "We shifted from purely headless CLI Docker deployments to leveraging Ubuntu Server with Cockpit web services for server management.",
          owner: "DevOps",
          targetDate: "Completed Aug 2026",
          status: "Implemented",
          impact: "Significantly reduces troubleshooting overhead for TLS handshake errors, memory leaks, and service logs.",
          actions: [
            "Configured hostname matching `.crt` SSL files in Cockpit.",
            "Created unified system administrative dashboard."
          ]
        }
      }
    ],
    decisions: [
      {
        id: "dec1",
        text: "<strong>Frontend Framework:</strong> Standardized on ClojureScript with Reagent/re-frame.",
        details: {
          category: "Important Decision",
          description: "Chosen over standard React/TypeScript to guarantee strict immutability and centralized event routing across complex salon calendar screens.",
          owner: "Architecture Lead",
          targetDate: "Locked In",
          status: "Active Standard",
          impact: "Eliminates state synchronization bugs across complex multi-paned interfaces.",
          actions: [
            "Document state subscription patterns in internal knowledge base.",
            "Maintain shadow-cljs build scripts."
          ]
        }
      }
    ],
    learnings: [
      {
        id: "l1",
        text: "<strong>Hardware Tooling:</strong> 500W spindles struggle with high-density materials compared to pulley-reduced 775 motors.",
        details: {
          category: "Key Learning",
          description: "Testing in our hardware lab showed 500W direct spindles stall under continuous load when milling aluminum brackets, whereas torque-reduced 775 motor setups maintain clean cutting speeds.",
          owner: "Hardware Lab",
          targetDate: "N/A",
          status: "Applied to Prototypes",
          impact: "Saves hardware iteration cycles by establishing high-torque baselines for future physical enclosures.",
          actions: [
            "Update hardware component specs for all CNC milling builds.",
            "Order 3:1 pulley reduction gear sets."
          ]
        }
      }
    ]
  },
  "july-2026": {
    priorities: [
      {
        id: "jul_p1",
        title: "1. Core Architecture Setup",
        outcome: "Establish base `project.clj` Leiningen configs for Carevoo.",
        details: {
          category: "July Milestone",
          description: "Initial foundational setup for the Carevoo repository using Clojure Leiningen project structures.",
          owner: "Siavash",
          targetDate: "July 2026",
          status: "Completed",
          impact: "Established unified repo structure for frontend and backend.",
          actions: ["Configured shadow-cljs and Leiningen aliases."]
        }
      }
    ],
    progress: [],
    risks: [],
    dependencies: [],
    changes: [],
    decisions: [],
    learnings: []
  },
  "june-2026": {
    priorities: [
      {
        id: "jun_p1",
        title: "1. Feasibility & Mathematical Modeling",
        outcome: "Finalize matrix logic required for scheduling algorithms.",
        details: {
          category: "June Milestone",
          description: "Theoretical ground-level work using difference matrices over finite groups to design scheduling logic.",
          owner: "Siavash",
          targetDate: "June 2026",
          status: "Completed",
          impact: "Validated mathematical feasibility for non-conflicting appointment slot generation.",
          actions: ["Drafted thesis abstract and algorithm specs."]
        }
      }
    ],
    progress: [],
    risks: [],
    dependencies: [],
    changes: [],
    decisions: [],
    learnings: []
  }
}

export default class extends Controller {
  static values = {
    periods: Object,
    selectedPeriod: String
  }

  static targets = [
    "content",
    "priorities",
    "progress",
    "risks",
    "dependencies",
    "changes",
    "decisions",
    "learnings",
    "overlay",
    "drawer",
    "drawerCategory",
    "drawerTitle",
    "drawerDescription",
    "drawerImpact",
    "drawerMeta",
    "drawerActions"
  ]

  connect() {
    const serverData = this.hasPeriodsValue ? this.periodsValue : null
    this.statusData = (serverData && Object.keys(serverData).length > 0) ? serverData : COMPANY_STATUS_DATA

    this.currentMonth = this.hasSelectedPeriodValue ? (this.selectedPeriodValue || "august-2026") : "august-2026"

    const selector = document.getElementById("company-month-selector")
    if (selector) {
      this.currentMonth = selector.value || this.currentMonth
    }

    this.renderCompanyStatus(this.currentMonth)

    this.handleContentClick = this.handleContentClick.bind(this)
    if (this.hasContentTarget) {
      this.contentTarget.addEventListener("click", this.handleContentClick)
    }
  }

  disconnect() {
    if (this.hasContentTarget) {
      this.contentTarget.removeEventListener("click", this.handleContentClick)
    }
  }

  changeMonth(event) {
    const monthId = event?.target?.value || "august-2026"
    this.currentMonth = monthId
    this.renderCompanyStatus(monthId)
  }

  renderCompanyStatus(monthId) {
    const data = this.statusData ? this.statusData[monthId] : COMPANY_STATUS_DATA[monthId]
    if (!data) return

    if (this.hasContentTarget) {
      this.contentTarget.style.opacity = "0.4"
    }

    setTimeout(() => {
      if (this.hasPrioritiesTarget) {
        this.prioritiesTarget.innerHTML = (data.priorities || []).map((priority) => `
          <div class="company-priority-item company-clickable" data-month-id="${monthId}" data-collection-key="priorities" data-item-id="${priority.id}">
            <span class="company-priority-title">${priority.title}</span>
            <span class="company-priority-outcome">Outcome: ${priority.outcome}</span>
          </div>
        `).join("") || '<span class="company-empty-note">No priorities recorded.</span>'
      }

      if (this.hasProgressTarget) {
        this.progressTarget.innerHTML = (data.progress && data.progress.length > 0)
          ? data.progress.map((progress) => `
            <div class="company-progress-row company-clickable" data-month-id="${monthId}" data-collection-key="progress" data-item-id="${progress.id}">
              <div class="company-progress-labels">
                <span>${progress.label}</span>
                <span>${progress.percent}%</span>
              </div>
              <div class="company-progress-bar-bg">
                <div class="company-progress-bar-fill" style="width: ${progress.percent}%; background: ${progress.color};"></div>
              </div>
              <span class="company-evidence-note">Evidence: ${progress.evidence}</span>
            </div>
          `).join("")
          : '<span class="company-empty-note">No items recorded.</span>'
      }

      if (this.hasRisksTarget) {
        this.risksTarget.innerHTML = (data.risks && data.risks.length > 0)
          ? data.risks.map((risk) => `
            <div class="company-risk-item ${risk.type} company-clickable" data-month-id="${monthId}" data-collection-key="risks" data-item-id="${risk.id}">
              <div class="company-risk-icon">${risk.icon}</div>
              <div class="company-risk-text">
                <span class="company-risk-title">${risk.title}</span>
                <span class="company-risk-desc">${risk.desc}</span>
              </div>
            </div>
          `).join("")
          : '<span class="company-empty-note">No immediate risks logged for this period.</span>'
      }

      if (this.hasDependenciesTarget) {
        this.dependenciesTarget.innerHTML = (data.dependencies && data.dependencies.length > 0)
          ? data.dependencies.map((dependency) => `
            <div class="company-dependency-row company-clickable" data-month-id="${monthId}" data-collection-key="dependencies" data-item-id="${dependency.id}">
              <span class="company-dep-tag">${dependency.from}</span>
              <span class="company-dep-arrow">→</span>
              <span class="company-dep-tag">${dependency.to}</span>
            </div>
          `).join("")
          : '<span class="company-empty-note">No dependencies logged.</span>'
      }

      if (this.hasChangesTarget) {
        this.changesTarget.innerHTML = (data.changes && data.changes.length > 0)
          ? data.changes.map((change) => `
            <li class="company-clickable" data-month-id="${monthId}" data-collection-key="changes" data-item-id="${change.id}">${change.text}</li>
          `).join("")
          : '<span class="company-empty-note">No changes logged.</span>'
      }

      if (this.hasDecisionsTarget) {
        this.decisionsTarget.innerHTML = (data.decisions && data.decisions.length > 0)
          ? data.decisions.map((decision) => `
            <li class="company-clickable" data-month-id="${monthId}" data-collection-key="decisions" data-item-id="${decision.id}">${decision.text}</li>
          `).join("")
          : '<span class="company-empty-note">No decisions logged.</span>'
      }

      if (this.hasLearningsTarget) {
        this.learningsTarget.innerHTML = (data.learnings && data.learnings.length > 0)
          ? data.learnings.map((learning) => `
            <li class="company-clickable" data-month-id="${monthId}" data-collection-key="learnings" data-item-id="${learning.id}">${learning.text}</li>
          `).join("")
          : '<span class="company-empty-note">No learnings logged.</span>'
      }

      if (this.hasContentTarget) {
        this.contentTarget.style.opacity = "1"
      }
    }, 120)
  }

  handleContentClick(event) {
    const clickable = event.target.closest(".company-clickable")
    if (!clickable) return

    const monthId = clickable.getAttribute("data-month-id") || this.currentMonth
    const collectionKey = clickable.getAttribute("data-collection-key")
    const itemId = clickable.getAttribute("data-item-id")

    if (monthId && collectionKey && itemId) {
      this.openDrawer(monthId, collectionKey, itemId)
    }
  }

  openDrawer(monthId, collectionKey, itemId) {
    const monthData = this.statusData ? this.statusData[monthId] : COMPANY_STATUS_DATA[monthId]
    if (!monthData || !monthData[collectionKey]) return

    const item = monthData[collectionKey].find((entry) => entry.id === itemId)
    if (!item || !item.details) return

    const details = item.details
    if (this.hasDrawerCategoryTarget) {
      this.drawerCategoryTarget.textContent = details.category || collectionKey.toUpperCase()
    }

    let displayTitle = "Detail Overview"
    if (item.title) {
      displayTitle = item.title
    } else if (item.label) {
      displayTitle = item.label
    } else if (item.from && item.to) {
      displayTitle = `${item.from} → ${item.to}`
    } else if (item.text) {
      const tempDiv = document.createElement("div")
      tempDiv.innerHTML = item.text
      const plainText = tempDiv.textContent || tempDiv.innerText || ""
      if (plainText.includes(":")) {
        displayTitle = plainText.split(":")[0]
      } else {
        displayTitle = plainText.length > 40 ? `${plainText.substring(0, 40)}...` : plainText
      }
    }

    if (this.hasDrawerTitleTarget) {
      this.drawerTitleTarget.textContent = displayTitle
    }

    if (this.hasDrawerDescriptionTarget) {
      this.drawerDescriptionTarget.textContent = details.description || ""
    }

    if (this.hasDrawerImpactTarget) {
      this.drawerImpactTarget.textContent = details.impact || ""
    }

    if (this.hasDrawerMetaTarget) {
      this.drawerMetaTarget.innerHTML = `
        <span class="company-meta-pill">👤 Owner: <strong>${details.owner || "Unassigned"}</strong></span>
        <span class="company-meta-pill">📅 Target: <strong>${details.targetDate || "N/A"}</strong></span>
        <span class="company-meta-pill">📊 Status: <strong>${details.status || "Open"}</strong></span>
      `
    }

    if (this.hasDrawerActionsTarget) {
      this.drawerActionsTarget.innerHTML = (details.actions || []).map((action) => `<li>${action}</li>`).join("")
    }

    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.add("active")
    }
  }

  closeDrawer() {
    if (this.hasOverlayTarget) {
      this.overlayTarget.classList.remove("active")
    }
  }

  closeDrawerOnBackdrop(event) {
    if (event.target === this.overlayTarget) {
      this.closeDrawer()
    }
  }
}
