import { Controller } from "@hotwired/stimulus"

// Simple toast controller - each toast is its own instance
export default class extends Controller {
  static values = {
    message: String,
    type: { type: String, default: "info" },
    duration: { type: Number, default: 3000 }
  }

  connect() {
    // Set up the toast appearance
    this.element.textContent = this.messageValue
    this.element.className = `toast toast-${this.typeValue}`

    // Show the toast
    this.show()
  }

  show() {
    // Trigger the CSS transition
    setTimeout(() => {
      this.element.classList.add("show")
    }, 10)

    // Auto-hide after duration
    if (this.durationValue > 0) {
      setTimeout(() => {
        this.hide()
      }, this.durationValue)
    }
  }

  hide() {
    this.element.classList.remove("show")

    // Remove from DOM after transition
    setTimeout(() => {
      if (this.element && this.element.parentNode) {
        this.element.remove()
      }
    }, 300)
  }

  // Click to dismiss
  click() {
    this.hide()
  }
}