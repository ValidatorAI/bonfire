import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "title", "path", "content", "loading", "error"]
  static values = {
    fileUrl: String
  }

  async openFile(event) {
    const { path, title } = event.params
    if (!path) return

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = title || path.split("/").pop()
    }
    if (this.hasPathTarget) {
      this.pathTarget.textContent = path
    }

    if (this.hasLoadingTarget) this.loadingTarget.hidden = false
    if (this.hasErrorTarget) this.errorTarget.hidden = true
    if (this.hasContentTarget) this.contentTarget.innerHTML = ""

    if (this.hasDialogTarget && !this.dialogTarget.open) {
      this.dialogTarget.showModal()
    }

    try {
      const url = new URL(this.fileUrlValue, window.location.origin)
      url.searchParams.set("path", path)

      const response = await fetch(url.toString(), {
        headers: {
          Accept: "application/json",
          "X-Requested-With": "XMLHttpRequest"
        }
      })

      if (!response.ok) {
        throw new Error(`Failed to load file (${response.status})`)
      }

      const data = await response.json()

      if (this.hasTitleTarget && data.title) {
        this.titleTarget.textContent = data.title
      }

      if (this.hasContentTarget) {
        this.contentTarget.innerHTML = data.rendered_html || `<pre>${this.escapeHtml(data.raw_content || "")}</pre>`
      }
    } catch (err) {
      console.error("Error loading markdown file:", err)
      if (this.hasErrorTarget) {
        this.errorTarget.hidden = false
        this.errorTarget.textContent = `Could not load ${path}: ${err.message}`
      }
    } finally {
      if (this.hasLoadingTarget) {
        this.loadingTarget.hidden = true
      }
    }
  }

  close() {
    if (this.hasDialogTarget && this.dialogTarget.open) {
      this.dialogTarget.close()
    }
  }

  closeOnBackdrop(event) {
    if (event.target === this.dialogTarget) {
      this.close()
    }
  }

  escapeHtml(str) {
    const div = document.createElement("div")
    div.textContent = str
    return div.innerHTML
  }
}
