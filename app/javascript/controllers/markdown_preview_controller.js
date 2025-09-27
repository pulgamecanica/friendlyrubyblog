import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview"]

  update() {
    const markdown = this.inputTarget.value
    // naive: just show text, later you can call a markdown renderer
    this.previewTarget.textContent = markdown
  }
}
