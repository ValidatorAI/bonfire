import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["dialog", "title", "meta", "notes"]

  open(event) {
    const { title, meta, notes } = event.params

    if (this.hasTitleTarget) {
      this.titleTarget.textContent = title || "Meeting Notes"
    }

    if (this.hasMetaTarget) {
      this.metaTarget.textContent = meta || ""
      this.metaTarget.hidden = !meta
    }

    if (this.hasNotesTarget) {
      if (notes && notes.trim().length > 0) {
        const paragraphs = notes.split(/\n\n+/).filter(Boolean)
        this.notesTarget.innerHTML = paragraphs
          .map((p) => `<p class="all-hands-notes-paragraph">${this.escapeHtml(p).replace(/\n/g, "<br>")}</p>`)
          .join("")
      } else {
        this.notesTarget.innerHTML = `<p class="all-hands-notes-empty">No detailed notes were recorded for this meeting.</p>`
      }
    }

    if (this.hasDialogTarget && !this.dialogTarget.open) {
      this.dialogTarget.showModal()
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
