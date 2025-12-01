import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["undoBtn", "redoBtn"]

  static values = {
    undoUrl: String,
    redoUrl: String,
    versionsUrl: String,
    panelId: String
  }

  get panel() {
    return document.getElementById(this.panelIdValue)
  }

  connect() {
    // Bind escape key handler
    this.boundEscapeKey = this.handleEscapeKey.bind(this)

    // Listen for successful restore/undo/redo to refresh version list if panel is open
    this.boundVersionChanged = this.handleVersionChanged.bind(this)
    document.addEventListener('version:changed', this.boundVersionChanged)
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundEscapeKey)
    document.removeEventListener('version:changed', this.boundVersionChanged)
  }

  // Open the version panel
  async openVersionPanel() {
    // Show the panel
    if (this.panel) {
      this.panel.classList.remove('hidden')

      try {
        const response = await fetch(this.versionsUrlValue, {
          headers: {
            'Accept': 'text/vnd.turbo-stream.html'
          }
        })

        if (response.ok) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)

          // Slide in animation
          setTimeout(() => {
            this.panel.classList.remove('translate-x-full')
          }, 10)

          // Add escape key listener
          document.addEventListener('keydown', this.boundEscapeKey)
        } else {
          console.error('Failed to load versions:', response.status, response.statusText)
        }
      } catch (error) {
        console.error('Error loading versions:', error)
      }
    }
  }

  // Close the version panel
  closeVersionPanel() {
    if (this.panel) {
      // Slide out animation
      this.panel.classList.add('translate-x-full')

      // Hide after animation completes
      setTimeout(() => {
        this.panel.classList.add('hidden')
      }, 300)

      // Remove escape key listener
      document.removeEventListener('keydown', this.boundEscapeKey)
    }
  }

  // Handle escape key to close panel
  handleEscapeKey(event) {
    if (event.key === 'Escape') {
      this.closeVersionPanel()
    }
  }

  preview() {
    alert("Preview")
  }

  // Undo to previous version
  async undo() {
    try {
      const response = await fetch(this.undoUrlValue, {
        method: 'PATCH',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)

        // Dispatch event to refresh version list if panel is open
        document.dispatchEvent(new CustomEvent('version:changed'))
      } else {
        console.error('Undo failed:', response.status, response.statusText)
        const text = await response.text()
        console.error('Response:', text)
      }
    } catch (error) {
      console.error('Error undoing version:', error)
    }
  }

  // Redo to next version
  async redo() {
    try {
      const response = await fetch(this.redoUrlValue, {
        method: 'PATCH',
        headers: {
          'Accept': 'text/vnd.turbo-stream.html',
          'X-CSRF-Token': this.getCSRFToken()
        }
      })

      if (response.ok) {
        const html = await response.text()
        Turbo.renderStreamMessage(html)

        // Dispatch event to refresh version list if panel is open
        document.dispatchEvent(new CustomEvent('version:changed'))
      } else {
        console.error('Redo failed:', response.status, response.statusText)
      }
    } catch (error) {
      console.error('Error redoing version:', error)
    }
  }

  // Handle version changed event (refresh version list if panel is open)
  async handleVersionChanged() {
    if (this.panel && !this.panel.classList.contains('hidden')) {
      try {
        const response = await fetch(this.versionsUrlValue, {
          headers: {
            'Accept': 'text/vnd.turbo-stream.html'
          }
        })

        if (response.ok) {
          const html = await response.text()
          Turbo.renderStreamMessage(html)
        } else {
          console.error('Failed to refresh versions:', response.status, response.statusText)
        }
      } catch (error) {
        console.error('Error refreshing versions:', error)
      }
    }
  }

  // Get CSRF token for requests
  getCSRFToken() {
    const token = document.querySelector('meta[name="csrf-token"]')
    return token ? token.content : ''
  }
}
