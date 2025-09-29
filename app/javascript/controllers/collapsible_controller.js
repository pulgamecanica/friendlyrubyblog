import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "toggle", "icon"]
  static values = {
    expanded: { type: Boolean, default: false },
    duration: { type: Number, default: 300 }
  }

  connect() {
    this.updateDisplay()
  }

  toggle() {
    this.expandedValue = !this.expandedValue
  }

  expandedValueChanged() {
    this.updateDisplay()
    this.animateToggle()
  }

  updateDisplay() {
    if (this.hasToggleTarget) {
      this.toggleTarget.setAttribute("aria-expanded", this.expandedValue)
    }

    if (this.hasIconTarget) {
      this.iconTarget.style.transform = this.expandedValue ? "rotate(180deg)" : "rotate(0deg)"
    }
  }

  animateToggle() {
    if (!this.hasContentTarget) return

    const content = this.contentTarget
    const isExpanding = this.expandedValue

    if (isExpanding) {
      // Expanding
      content.style.display = "block"
      content.style.height = "0px"
      content.style.overflow = "hidden"

      // Force reflow
      content.offsetHeight

      content.style.transition = `height ${this.durationValue}ms ease-out`
      content.style.height = content.scrollHeight + "px"

      setTimeout(() => {
        content.style.height = "auto"
        content.style.overflow = "visible"
        content.style.transition = ""
      }, this.durationValue)
    } else {
      // Collapsing
      content.style.height = content.scrollHeight + "px"
      content.style.overflow = "hidden"
      content.style.transition = `height ${this.durationValue}ms ease-out`

      // Force reflow
      content.offsetHeight

      content.style.height = "0px"

      setTimeout(() => {
        content.style.display = "none"
        content.style.transition = ""
      }, this.durationValue)
    }
  }

  expand() {
    this.expandedValue = true
  }

  collapse() {
    this.expandedValue = false
  }
}