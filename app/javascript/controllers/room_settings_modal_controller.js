import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "frame" ]

  open(event) {
    event.preventDefault()

    const url = event.currentTarget.dataset.roomSettingsModalUrlParam
    if (!url) return

    this.frameTarget.src = url

    if (!this.dialogTarget.open) {
      this.dialogTarget.showModal()
    }
  }

  close() {
    if (this.dialogTarget.open) this.dialogTarget.close()
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) this.close()
  }

  reset() {
    this.frameTarget.removeAttribute("src")
  }
}
