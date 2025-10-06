import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["image", "indicator"]

  connect() {
    this.currentIndex = parseInt(this.element.dataset.startIndex || 0)
    this.updateDisplay()

    // Keyboard navigation
    this.boundKeyHandler = this.handleKeyPress.bind(this)

    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.attributeName === 'open') {
          if (this.element.open) {
            // Re-read start index when modal opens
            this.currentIndex = parseInt(this.element.dataset.startIndex || 0)
            this.updateDisplay()
            document.addEventListener('keydown', this.boundKeyHandler)
          } else {
            document.removeEventListener('keydown', this.boundKeyHandler)
          }
        }
      })
    })

    observer.observe(this.element, { attributes: true })
  }

  handleKeyPress(e) {
    if (!this.element.open) return

    switch(e.key) {
      case 'ArrowLeft':
        this.previous()
        break
      case 'ArrowRight':
        this.next()
        break
      case 'Escape':
        this.element.close()
        break
    }
  }

  closeOnBackdrop(event) {
    // Only close if clicking directly on the dialog (backdrop), not its children
    if (event.target === this.element) {
      this.element.close()
    }
  }

  previous() {
    if (this.imageTargets.length <= 1) return
    this.currentIndex = (this.currentIndex - 1 + this.imageTargets.length) % this.imageTargets.length
    this.updateDisplay()
  }

  next() {
    if (this.imageTargets.length <= 1) return
    this.currentIndex = (this.currentIndex + 1) % this.imageTargets.length
    this.updateDisplay()
  }

  goTo(event) {
    this.currentIndex = parseInt(event.currentTarget.dataset.index)
    this.updateDisplay()
  }

  updateDisplay() {
    // Update images
    this.imageTargets.forEach((img, index) => {
      if (index === this.currentIndex) {
        img.classList.remove('hidden')
      } else {
        img.classList.add('hidden')
      }
    })

    // Update indicators
    if (this.hasIndicatorTarget) {
      this.indicatorTargets.forEach((indicator, index) => {
        if (index === this.currentIndex) {
          indicator.classList.remove('bg-white/50')
          indicator.classList.add('bg-white')
        } else {
          indicator.classList.remove('bg-white')
          indicator.classList.add('bg-white/50')
        }
      })
    }
  }

  disconnect() {
    document.removeEventListener('keydown', this.boundKeyHandler)
  }
}
