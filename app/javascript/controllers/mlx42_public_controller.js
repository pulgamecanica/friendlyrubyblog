import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "console", "loader", "controlsIndicator", "consoleSection", "codeSection", "canvasContainer", "controlsButton"]
  static values = {
    jsUrl: String,
    wasmUrl: String,
    dataUrl: String,
    blockId: String
  }

  connect() {
    this.controlsActive = false
    this.consoleVisible = false
    this.codeVisible = false
    this.moduleInstance = null
    this.scriptLoaded = false

    // Auto-run on connect
    this.run()
  }

  disconnect() {
    this.cleanup()
  }

  run() {
    if (!this.hasJsUrlValue || !this.jsUrlValue) {
      this.log("❌ No compiled WASM available.")
      this.hideLoader()
      return
    }

    if (this.scriptLoaded) {
      return
    }

    const scriptId = `mlx42_script_${this.blockIdValue}`
    const existingScript = document.getElementById(scriptId)

    if (existingScript) {
      this.scriptLoaded = true
      this.hideLoader()
      return
    }

    this.log("🚀 Loading MLX42 program...")

    // Configure Emscripten Module
    const moduleConfig = {
      locateFile: (path) => {
        if (path.endsWith('.wasm')) {
          return this.wasmUrlValue
        } else if (path.endsWith('.data')) {
          return this.dataUrlValue || path
        }
        return path
      },
      canvas: this.canvasTarget,
      print: (text) => {
        this.log(text)
      },
      printErr: (text) => {
        this.log(`ERROR: ${text}`)
      }
    }

    // Timeout for loading
    const loadTimeout = setTimeout(() => {
      if (!this.scriptLoaded) {
        this.log("❌ Loading timeout. Please refresh the page.")
        this.hideLoader()
      }
    }, 15000)

    // Load Emscripten JS
    const script = document.createElement("script")
    script.id = scriptId
    script.src = this.jsUrlValue
    script.onload = () => {
      clearTimeout(loadTimeout)
      this.scriptLoaded = true
      this.log("✅ Script loaded, initializing...")

      // Call the module factory function
      if (typeof createMlx42Module === 'function') {
        createMlx42Module(moduleConfig).then((instance) => {
          this.moduleInstance = instance
          this.log("✅ MLX42 program running")
          this.log("💡 Click canvas to activate controls")
          this.hideLoader()
        }).catch((error) => {
          this.log(`❌ Initialization failed: ${error}`)
          this.hideLoader()
        })
      } else {
        this.log("❌ Module function not found")
        this.hideLoader()
      }
    }
    script.onerror = (error) => {
      clearTimeout(loadTimeout)
      this.log(`❌ Failed to load: ${error}`)
      this.hideLoader()
    }

    document.body.appendChild(script)
  }

  toggleControls() {
    this.controlsActive = !this.controlsActive

    // Update indicator
    if (this.hasControlsIndicatorTarget) {
      if (this.controlsActive) {
        this.controlsIndicatorTarget.classList.remove('hidden')
      } else {
        this.controlsIndicatorTarget.classList.add('hidden')
      }
    }

    // Update button icon
    if (this.hasControlsButtonTarget) {
      const svg = this.controlsButtonTarget.querySelector('svg')
      if (svg) {
        if (this.controlsActive) {
          // Unlocked icon
          svg.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 11V7a4 4 0 118 0m-4 8v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2z"/>'
        } else {
          // Locked icon
          svg.innerHTML = '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"/>'
        }
      }
    }

    // Enable/disable scroll prevention
    if (this.controlsActive) {
      this.enableScrollPrevention()
      this.log("🎮 Controls activated - keyboard/mouse locked")
    } else {
      this.disableScrollPrevention()
      this.log("🎮 Controls deactivated - keyboard/mouse unlocked")
    }
  }

  toggleCode() {
    this.codeVisible = !this.codeVisible

    if (this.hasCodeSectionTarget) {
      if (this.codeVisible) {
        this.codeSectionTarget.classList.remove('hidden')
      } else {
        this.codeSectionTarget.classList.add('hidden')
      }
    }
  }

  toggleConsole() {
    this.consoleVisible = !this.consoleVisible

    if (this.hasConsoleSectionTarget) {
      if (this.consoleVisible) {
        this.consoleSectionTarget.classList.remove('hidden')
      } else {
        this.consoleSectionTarget.classList.add('hidden')
      }
    }
  }

  openFullscreen() {
    const modal = document.getElementById(`mlx42-modal-${this.blockIdValue}`)
    if (modal) {
      // Store original canvas parent and position
      this.originalCanvasParent = this.canvasTarget.parentElement
      this.originalCanvasIndex = Array.from(this.originalCanvasParent.children).indexOf(this.canvasTarget)

      // Move main canvas to modal container
      const modalContainer = document.getElementById(`mlx42-modal-${this.blockIdValue}-canvas-container`)
      if (modalContainer) {
        this.canvasTarget.classList.add('w-full', 'h-full', 'rounded-lg')
        modalContainer.appendChild(this.canvasTarget)
      }

      // Automatically lock controls
      if (!this.controlsActive) {
        this.toggleControls()
      }

      // Show modal
      modal.showModal()

      // Listen for modal close
      const handleClose = () => {
        this.closeFullscreen()
        modal.removeEventListener('close', handleClose)
      }
      modal.addEventListener('close', handleClose)
    }
  }

  closeFullscreen() {
    // Move canvas back to original position
    if (this.originalCanvasParent && this.canvasTarget) {
      // Restore original canvas classes
      this.canvasTarget.classList.remove('h-full', 'rounded-lg')

      if (this.originalCanvasIndex >= this.originalCanvasParent.children.length) {
        this.originalCanvasParent.appendChild(this.canvasTarget)
      } else {
        this.originalCanvasParent.insertBefore(
          this.canvasTarget,
          this.originalCanvasParent.children[this.originalCanvasIndex]
        )
      }
    }

    // Automatically unlock controls
    if (this.controlsActive) {
      this.toggleControls()
    }

    // Clean up
    this.originalCanvasParent = null
    this.originalCanvasIndex = null
  }

  clearConsole() {
    if (this.hasConsoleTarget) {
      this.consoleTarget.value = ""
    }
  }

  enableScrollPrevention() {
    this.boundPreventScroll = this.preventDefault.bind(this)
    this.boundPreventScrollKeys = this.preventScrollKeys.bind(this)

    document.addEventListener("wheel", this.boundPreventScroll, { passive: false })
    document.addEventListener("touchmove", this.boundPreventScroll, { passive: false })
    document.addEventListener("keydown", this.boundPreventScrollKeys, { passive: false })
  }

  disableScrollPrevention() {
    if (this.boundPreventScroll) {
      document.removeEventListener("wheel", this.boundPreventScroll)
      document.removeEventListener("touchmove", this.boundPreventScroll)
    }
    if (this.boundPreventScrollKeys) {
      document.removeEventListener("keydown", this.boundPreventScrollKeys)
    }
  }

  preventDefault(e) {
    e.preventDefault()
  }

  preventScrollKeys(e) {
    const scrollKeys = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space', 'PageUp', 'PageDown', 'Home', 'End']
    if (scrollKeys.includes(e.key) || scrollKeys.includes(e.code)) {
      e.preventDefault()
    }
  }

  log(message) {
    if (this.hasConsoleTarget) {
      this.consoleTarget.value += message + "\n"
      this.consoleTarget.scrollTop = this.consoleTarget.scrollHeight
    }
  }

  hideLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.display = "none"
    }
  }

  cleanup() {
    this.disableScrollPrevention()

    if (this.moduleInstance) {
      this.moduleInstance = null
    }

    const scriptId = `mlx42_script_${this.blockIdValue}`
    const existingScript = document.getElementById(scriptId)

    if (existingScript) {
      existingScript.remove()
    }

    this.scriptLoaded = false
  }
}
