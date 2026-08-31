import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "openCount", "openBadge", "overdueCount", "aiCount", "card", "item", "emptyState" ]

  connect() {
    this.updateCounts()
  }

  resolve(event) {
    event.preventDefault()
    const button = event.currentTarget
    const item = button.closest("[data-home-attention-target='item']")
    if (!item || item.classList.contains("resolved")) return

    const resolveUrl = button.dataset.resolveUrl
    if (resolveUrl) {
      const token = document.querySelector('meta[name="csrf-token"]')?.getAttribute("content")
      fetch(resolveUrl, {
        method: "PATCH",
        headers: {
          "X-CSRF-Token": token,
          "Accept": "application/json",
          "Content-Type": "application/json"
        }
      }).catch(err => console.error("Error resolving attention item:", err))
    }

    item.classList.add("resolved")
    item.style.pointerEvents = "none"
    button.textContent = "Done"
    button.disabled = true

    this.updateCounts()
  }

  updateCounts() {
    const openItems = this.itemTargets.filter(item => !item.classList.contains("resolved"))
    const overdueItems = openItems.filter(item => item.dataset.overdue === "true")
    const aiItems = openItems.filter(item => item.dataset.aiConfirm === "true")

    if (this.hasOpenCountTarget) {
      this.openCountTarget.textContent = String(openItems.length)
    }

    if (this.hasOpenBadgeTarget) {
      this.openBadgeTarget.textContent = `${openItems.length} Open`
    }

    if (this.hasOverdueCountTarget) {
      this.overdueCountTarget.textContent = String(overdueItems.length)
    }

    if (this.hasAiCountTarget) {
      this.aiCountTarget.textContent = String(aiItems.length)
    }

    if (this.hasCardTarget) {
      this.cardTargets.forEach(card => {
        const cardItems = card.querySelectorAll("[data-home-attention-target='item']:not(.resolved)")
        const countBadge = card.querySelector(".home-card-count")
        if (countBadge) {
          countBadge.textContent = String(cardItems.length)
        }
      })
    }

    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.style.display = openItems.length === 0 ? "block" : "none"
    }
  }
}
