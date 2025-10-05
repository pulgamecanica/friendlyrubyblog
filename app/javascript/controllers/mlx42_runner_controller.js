import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "console", "loader", "captureIndicator"]
  static values = {
    jsUrl: String,
    wasmUrl: String,
    dataUrl: String,
    blockId: String
  }

  connect() {
    this.captured = false
    this.moduleInstance = null
    this.scriptLoaded = false
    this.boundHandlePointerLockChange = this.handlePointerLockChange.bind(this)
    this.boundPreventScroll = this.preventDefault.bind(this)
    document.addEventListener("pointerlockchange", this.boundHandlePointerLockChange)

    // Don't auto-run - user must click Run button to avoid keyboard capture issues
    if (!this.hasJsUrlValue || !this.jsUrlValue) {
      this.log("⚠️ No compiled WebAssembly available. Please compile your code first.")
    } else {
      this.log("✅ Ready to run. Click the Run button in the toolbar.")
    }
  }

  disconnect() {
    this.cleanup()
    document.removeEventListener("pointerlockchange", this.boundHandlePointerLockChange)
    this.disableScrollPrevention()
  }

  preventDefault(e) {
    e.preventDefault()
  }

  preventScrollKeys(e) {
    // Prevent arrow keys, space, page up/down from scrolling
    const scrollKeys = ['ArrowUp', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'Space', 'PageUp', 'PageDown', 'Home', 'End']
    if (scrollKeys.includes(e.key) || scrollKeys.includes(e.code)) {
      e.preventDefault()
    }
  }

  enableScrollPrevention() {
    // Prevent scrolling with wheel, touch, and keyboard
    this.boundPreventScrollKeys = this.preventScrollKeys.bind(this)
    document.addEventListener("wheel", this.boundPreventScroll, { passive: false })
    document.addEventListener("touchmove", this.boundPreventScroll, { passive: false })
    document.addEventListener("keydown", this.boundPreventScrollKeys, { passive: false })
  }

  disableScrollPrevention() {
    document.removeEventListener("wheel", this.boundPreventScroll)
    document.removeEventListener("touchmove", this.boundPreventScroll)
    if (this.boundPreventScrollKeys) {
      document.removeEventListener("keydown", this.boundPreventScrollKeys)
    }
  }

  run() {
    if (!this.hasJsUrlValue || !this.jsUrlValue) {
      this.log("❌ No compiled WASM available. Please compile first.")
      return
    }

    if (this.scriptLoaded) {
      this.log("⚠️ Already loaded. Refresh page to reload.")
      return
    }

    // Check if this specific script is already in DOM
    const scriptId = `mlx42_script_${this.blockIdValue}`
    const existingScript = document.getElementById(scriptId)

    if (existingScript) {
      this.log("⚠️ Script already loaded in page.")
      this.scriptLoaded = true
      return
    }

    this.showLoader()
    this.clearConsole()
    this.log("🚀 Loading WebAssembly module...")

    // Configure Emscripten Module options
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

    // Set timeout for loading
    const loadTimeout = setTimeout(() => {
      if (!this.scriptLoaded) {
        this.log("❌ Loading timeout. Check network or try recompiling.")
        this.hideLoader()
      }
    }, 10000) // 10 second timeout

    // Load the Emscripten-generated JavaScript
    const script = document.createElement("script")
    script.id = scriptId
    script.src = this.jsUrlValue
    script.onload = () => {
      clearTimeout(loadTimeout)
      this.scriptLoaded = true
      this.log("✅ Module script loaded, initializing...")

      // Call the module factory function (MODULARIZE=1)
      if (typeof createMlx42Module === 'function') {
        createMlx42Module(moduleConfig).then((instance) => {
          this.moduleInstance = instance
          this.log("✅ WebAssembly module initialized successfully")
          this.hideLoader()
        }).catch((error) => {
          this.log(`❌ Module initialization failed: ${error}`)
          this.hideLoader()
        })
      } else {
        this.log("❌ createMlx42Module function not found - recompile may be needed")
        this.hideLoader()
      }
    }
    script.onerror = (error) => {
      clearTimeout(loadTimeout)
      this.log(`❌ Failed to load WebAssembly: ${error}`)
      this.log("Check console for details or try recompiling.")
      this.hideLoader()
    }

    document.body.appendChild(script)
  }

  toggleCapture() {
    // Toggle scroll prevention (not pointer lock)
    this.captured = !this.captured

    if (this.hasCaptureIndicatorTarget) {
      this.captureIndicatorTarget.style.display = this.captured ? "block" : "none"
      this.captureIndicatorTarget.textContent = this.captured ? "🎮 Controls Active (Click to disable)" : ""
    }

    // Prevent scrolling when controls are active
    if (this.captured) {
      this.enableScrollPrevention()
    } else {
      this.disableScrollPrevention()
    }
  }

  handlePointerLockChange() {
    // Not using pointer lock anymore, but keep the listener to avoid errors
  }

  log(message) {
    if (this.hasConsoleTarget) {
      this.consoleTarget.value += message + "\n"
      this.consoleTarget.scrollTop = this.consoleTarget.scrollHeight
    }
  }

  clearConsole() {
    if (this.hasConsoleTarget) {
      this.consoleTarget.value = ""
    }
  }

  showLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.display = "block"
    }
  }

  hideLoader() {
    if (this.hasLoaderTarget) {
      this.loaderTarget.style.display = "none"
    }
  }

  cleanup() {
    if (this.captured) {
      this.captured = false
      this.disableScrollPrevention()
    }

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
