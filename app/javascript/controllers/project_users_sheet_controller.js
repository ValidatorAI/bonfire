import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { refreshProjectSettings: Boolean }

  connect() {
    if (!this.refreshProjectSettingsValue) return

    // Notify parent project settings page to refresh teammate list.
    window.parent.postMessage({ type: "project-users:refresh-project" }, window.location.origin)
  }
}
