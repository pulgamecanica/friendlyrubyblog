import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["contentView", "canvasView", "toggleButton", "runButton", "captureButton"]

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
}
