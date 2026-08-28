import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { trigger: Boolean }

  connect() {
    if (!this.triggerValue) return

    this.dispatch("visible", { target: window, prefix: "refresh-room" })
  }
}
