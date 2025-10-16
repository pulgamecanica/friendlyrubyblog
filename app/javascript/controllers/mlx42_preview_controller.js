import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contentView", "canvasView", "toggleCodeButton", "exportButton", "importButton", "exportStatus"]

  connect() {
    this.showingCode = false
    this.updateView()
  }

  disconnect() {
    this.cleanupRunner()
  }

  toggleCodeView() {
    this.showingCode = !this.showingCode
    this.updateView()
  }

  cleanupRunner() {
    const runnerElement = this.canvasViewTarget.querySelector('[data-controller*="mlx42-runner"]')

    if (runnerElement) {
      const runnerController = this.application.getControllerForElementAndIdentifier(runnerElement, "mlx42-runner")

      if (runnerController) {
        runnerController.cleanup()
      }
    }
  }

  updateView() {
    if (this.showingCode) {
      // Show code view
      this.contentViewTarget.style.display = "block"

      // Trigger syntax highlighting
      this.highlightCode()
    } else {
      // Hide code view (canvas always visible)
      this.contentViewTarget.style.display = "none"
    }
  }

  highlightCode() {
    // Find code elements and highlight them with Prism
    const codeElements = this.contentViewTarget.querySelectorAll('code[class*="language-"]')

    codeElements.forEach(codeElement => {
      // Check if already highlighted
      if (!codeElement.querySelector('.token')) {
        if (window.Prism) {
          window.Prism.highlightElement(codeElement)
        } else {
          // Import and highlight
          import('prismjs').then((Prism) => {
            Prism.default.highlightElement(codeElement)
          })
        }
      }
    })
  }

  triggerRun() {
    // Find the mlx42-runner controller inside canvasView and call run()
    const runnerElement = this.canvasViewTarget.querySelector('[data-controller*="mlx42-runner"]')
    if (runnerElement) {
      const runnerController = this.application.getControllerForElementAndIdentifier(runnerElement, "mlx42-runner")
      if (runnerController) {
        runnerController.run()
      }
    }
  }

  triggerCapture() {
    // Find the mlx42-runner controller inside canvasView and call toggleCapture()
    const runnerElement = this.canvasViewTarget.querySelector('[data-controller*="mlx42-runner"]')
    if (runnerElement) {
      const runnerController = this.application.getControllerForElementAndIdentifier(runnerElement, "mlx42-runner")
      if (runnerController) {
        runnerController.toggleCapture()

        // Update button text based on captured state
        if (this.hasCaptureButtonTarget) {
          this.captureButtonTarget.textContent = runnerController.captured ? "🎮 Disable Controls" : "🎮 Enable Controls"
        }
      }
    }
  }

  async triggerExport() {
    const article = this.canvasViewTarget.closest('article[data-controller*="mlx42-preview"]') || this.element.closest('article')
    let runnerElement = article?.querySelector('[data-controller~="mlx42-runner"]')

    if (!runnerElement) return

    const runnerController = this.application.getControllerForElementAndIdentifier(runnerElement, "mlx42-runner")
    if (!runnerController) return

    this.exportStatusTarget.innerHTML = `
      <button disabled class="w-full px-2 py-1.5 text-xs bg-gray-300 text-gray-700 rounded cursor-not-allowed">
        📦 Preparing export...
      </button>
    `
    // Indicate start
    this.exportStatusTarget.textContent = "📦 Preparing export..."

    try {
      const zipUrl = await runnerController.exportFiles(statusMessage => {
        // Update loading button text
        const btn = this.exportStatusTarget.querySelector('button')
        if (btn) btn.textContent = statusMessage
      })

      if (zipUrl) {
        this.exportStatusTarget.innerHTML = `
          <a href="${zipUrl}" target="_blank" class="w-full inline-block text-center px-2 py-1.5 text-xs bg-blue-500 text-white rounded hover:bg-blue-600 transition-colors">
            📦 Download ZIP
          </a>
        `
      } else {
        this.exportStatusTarget.innerHTML = `
          <button disabled class="w-full px-2 py-1.5 text-xs bg-red-500 text-white rounded cursor-not-allowed">
            ❌ Export failed
          </button>
        `
      }
    } catch (err) {
      this.exportStatusTarget.innerHTML = `
        <button disabled class="w-full px-2 py-1.5 text-xs bg-red-500 text-white rounded cursor-not-allowed">
          ❌ Export error
        </button>
      `
      console.error(err)
    }
  }

  triggerImport(event) {
    const article = this.canvasViewTarget.closest('article[data-controller*="mlx42-preview"]') || this.element.closest('article')
    let runnerElement = article?.querySelector('[data-controller~="mlx42-runner"]')

    // Find the mlx42-runner controller inside canvasView and call importFiles()
    if (runnerElement) {
      const runnerController = this.application.getControllerForElementAndIdentifier(runnerElement, "mlx42-runner")
      if (runnerController) {
        runnerController.importFiles(event)
      }
    }
  }
}
