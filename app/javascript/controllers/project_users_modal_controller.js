import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "dialog", "frame" ]

  connect() {
    this.onMessage = this.handleMessage.bind(this)
    window.addEventListener("message", this.onMessage)
  }

  disconnect() {
    window.removeEventListener("message", this.onMessage)
  }

  open(event) {
    event.preventDefault()

    const url = event.currentTarget.dataset.projectUsersModalUrlParam
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

  handleMessage(event) {
    if (event.origin !== window.location.origin) return
    if (!event.data || event.data.type !== "project-users:refresh-project") return

    window.location.reload()
  }
}
