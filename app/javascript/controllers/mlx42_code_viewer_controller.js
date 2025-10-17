import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tab", "content"]

  switchFile(event) {
    const clickedIndex = parseInt(event.currentTarget.dataset.index, 10)

    // Update tab styles
    this.tabTargets.forEach((tab, index) => {
      if (index === clickedIndex) {
        tab.className = "px-3 py-1.5 text-xs rounded transition-colors whitespace-nowrap bg-purple-600 text-white"
      } else {
        tab.className = "px-3 py-1.5 text-xs rounded transition-colors whitespace-nowrap bg-gray-700 text-gray-300 hover:bg-gray-600"
      }
    })

    // Show/hide content
    this.contentTargets.forEach((content, index) => {
      if (parseInt(content.dataset.index, 10) === clickedIndex) {
        content.style.display = "block"
      } else {
        content.style.display = "none"
      }
    })

    // Trigger syntax highlighting if Prism is available
    this.highlightCode()
  }

  highlightCode() {
    if (window.Prism) {
      // Find visible code blocks and highlight
      this.contentTargets.forEach(content => {
        if (content.style.display !== "none") {
          const codeElement = content.querySelector('code')
          if (codeElement && !codeElement.querySelector('.token')) {
            window.Prism.highlightElement(codeElement)
          }
        }
      })
    }
  }

  connect() {
    // Highlight on initial load
    setTimeout(() => this.highlightCode(), 100)
  }
}
