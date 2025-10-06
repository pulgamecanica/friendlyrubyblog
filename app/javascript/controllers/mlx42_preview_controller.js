import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contentView", "canvasView", "toggleButton", "runButton", "captureButton", "exportButton", "importButton", "exportStatus"]

  connect() {
    this.showingCanvas = false
    this.updateView()
  }

  disconnect() {
    this.cleanupRunner()
  }

  toggleView() {
    if (this.showingCanvas) {
      this.cleanupRunner()
    }

    this.showingCanvas = !this.showingCanvas
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
    if (this.showingCanvas) {
      this.contentViewTarget.style.display = "none"
      this.canvasViewTarget.style.display = "block"
      if (this.hasToggleButtonTarget) {
        this.toggleButtonTarget.textContent = "📝 Show Content"
      }
      if (this.hasRunButtonTarget) {
        this.runButtonTarget.style.display = "block"
      }
      if (this.hasCaptureButtonTarget) {
        this.captureButtonTarget.style.display = "block"
      }
    } else {
      this.contentViewTarget.style.display = "block"
      this.canvasViewTarget.style.display = "none"
      if (this.hasToggleButtonTarget) {
        this.toggleButtonTarget.textContent = "📺 Show Canvas"
      }
      if (this.hasRunButtonTarget) {
        this.runButtonTarget.style.display = "none"
      }
      if (this.hasCaptureButtonTarget) {
        this.captureButtonTarget.style.display = "none"
      }
    }
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
