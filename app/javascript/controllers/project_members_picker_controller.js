import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["list", "select", "addButton", "inputs", "empty"]
  static values = { currentUserId: Number }

  add() {
    const option = this.selectTarget.selectedOptions[0]
    if (!option) return

    const userId = Number.parseInt(option.value, 10)
    if (!userId || userId === this.currentUserIdValue || this.hasSelectedMember(userId)) return

    const name = option.dataset.name || option.textContent.trim()
    const initials = option.dataset.initials || name.charAt(0).toUpperCase()

    this.listTarget.insertAdjacentHTML("beforeend", this.memberChipHtml(userId, name, initials))
    this.inputsTarget.insertAdjacentHTML("beforeend", `<input type="hidden" name="member_user_ids[]" value="${userId}">`)

    option.remove()
    this.selectTarget.value = ""
    this.updateControls()
  }

  remove(event) {
    const userId = Number.parseInt(event.currentTarget.dataset.memberId, 10)
    if (!userId || userId === this.currentUserIdValue) return

    const chip = event.currentTarget.closest(".member-chip")
    if (!chip) return

    const name = chip.dataset.memberName
    const initials = chip.dataset.memberInitials

    chip.remove()
    this.removeHiddenInput(userId)
    this.appendOption(userId, name, initials)
    this.updateControls()
  }

  updateControls() {
    const noOptions = this.selectTarget.options.length <= 1
    this.addButtonTarget.disabled = noOptions
    this.emptyTarget.hidden = !noOptions
  }

  appendOption(userId, name, initials) {
    const option = document.createElement("option")
    option.value = String(userId)
    option.dataset.name = name
    option.dataset.initials = initials
    option.textContent = name
    this.selectTarget.appendChild(option)
  }

  removeHiddenInput(userId) {
    const input = this.inputsTarget.querySelector(`input[name=\"member_user_ids[]\"][value=\"${userId}\"]`)
    if (input) input.remove()
  }

  hasSelectedMember(userId) {
    return this.inputsTarget.querySelector(`input[name=\"member_user_ids[]\"][value=\"${userId}\"]`) !== null
  }

  memberChipHtml(userId, name, initials) {
    const safeName = this.escapeHtml(name)
    const safeInitials = this.escapeHtml(initials)

    return `
      <span class="member-chip" data-member-id="${userId}" data-member-name="${safeName}" data-member-initials="${safeInitials}">
        <span class="member-chip-avatar">${safeInitials}</span>
        <span>${safeName}</span>
        <button type="button"
                class="member-chip-remove"
                data-member-id="${userId}"
                data-action="click->project-members-picker#remove"
                aria-label="Remove ${safeName}">
          Remove
        </button>
      </span>
    `
  }

  escapeHtml(value) {
    return String(value)
      .replaceAll("&", "&amp;")
      .replaceAll("<", "&lt;")
      .replaceAll(">", "&gt;")
      .replaceAll('"', "&quot;")
      .replaceAll("'", "&#39;")
  }
}
