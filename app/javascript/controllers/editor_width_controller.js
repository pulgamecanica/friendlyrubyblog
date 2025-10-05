import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Load saved state from localStorage
    const isExpanded = localStorage.getItem("editorExpanded") === "true"
    this.setWidth(isExpanded)
  }

  toggle() {
    const currentlyExpanded = !this.containerTarget.classList.contains("max-w-6xl")
    const newExpandedState = !currentlyExpanded

    this.setWidth(newExpandedState)
    localStorage.setItem("editorExpanded", newExpandedState)
  }

  setWidth(expanded) {
    if (expanded) {
      this.containerTarget.classList.remove("max-w-6xl")
      this.containerTarget.classList.add("max-w-full")
    } else {
      this.containerTarget.classList.remove("max-w-full")
      this.containerTarget.classList.add("max-w-6xl")
    }
  }
}
