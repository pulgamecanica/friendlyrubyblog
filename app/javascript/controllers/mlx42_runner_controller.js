import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["canvas", "console", "loader", "captureIndicator", "consoleSection", "canvasContainer", "controlsButton", "importInput", "exportUrl", "playOverlay"]
  static values = {
    jsUrl: String,
    wasmUrl: String,
    dataUrl: String,
    blockId: String,
    exportUrl: String
  }

  connect() {
    this.captured = false
    this.controlsLocked = false
    this.consoleVisible = false
    this.moduleInstance = null
    this.scriptLoaded = false
    this.boundHandlePointerLockChange = this.handlePointerLockChange.bind(this)
    this.boundPreventScroll = this.preventDefault.bind(this)
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this)
    this.boundHandleScroll = this.handleScroll.bind(this)

    document.addEventListener("pointerlockchange", this.boundHandlePointerLockChange)

    // Lazy loading - wait for user to click "Play"
    // Overlay will be visible by default, waiting for click
  }

  play() {
    // Hide the play overlay and start loading the WebAssembly
    if (this.hasPlayOverlayTarget) {
      this.playOverlayTarget.style.display = 'none'
    }

    // Start the WebAssembly module
    this.run()
  }

  disconnect() {
    this.cleanup()
    document.removeEventListener("pointerlockchange", this.boundHandlePointerLockChange)
    document.removeEventListener("click", this.boundHandleOutsideClick)
    document.removeEventListener("scroll", this.boundHandleScroll, true)
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

  toggleCapture(event) {
    // Double-click to toggle lock
    if (event && event.detail === 2) {
      this.controlsLocked = !this.controlsLocked
      this.log(this.controlsLocked ? "🔒 Controls locked (won't auto-release)" : "🔓 Controls unlocked")
      this.updateCaptureIndicator()
      return
    }

    // Toggle scroll prevention (not pointer lock)
    this.captured = !this.captured

    // Prevent scrolling when controls are active
    if (this.captured) {
      this.enableScrollPrevention()
      this.log("🎮 Controls activated (click outside or scroll to release)")
      document.addEventListener("click", this.boundHandleOutsideClick)
      document.addEventListener("scroll", this.boundHandleScroll, true)
    } else {
      this.disableScrollPrevention()
      this.log("🎮 Controls deactivated")
      document.removeEventListener("click", this.boundHandleOutsideClick)
      document.removeEventListener("scroll", this.boundHandleScroll, true)
      this.controlsLocked = false
    }

    this.updateCaptureIndicator()
  }

  updateCaptureIndicator() {
    if (this.hasCaptureIndicatorTarget) {
      if (this.captured) {
        this.captureIndicatorTarget.style.display = "block"
        const statusText = this.captureIndicatorTarget.querySelector('span')
        if (statusText) {
          statusText.textContent = this.controlsLocked
            ? "Controls Active (Locked - Double-click to unlock)"
            : "Controls Active (Click outside to release)"
        }
      } else {
        this.captureIndicatorTarget.style.display = "none"
      }
    }
  }

  handleOutsideClick(event) {
    // If controls are locked, don't auto-release
    if (this.controlsLocked) return

    // Check if click is outside the canvas container
    if (this.hasCanvasContainerTarget && !this.canvasContainerTarget.contains(event.target)) {
      this.log("👆 Click outside detected - releasing controls")
      if (this.captured) {
        this.toggleCapture()
      }
    }
  }

  handleScroll(event) {
    // Auto-release on scroll (even if locked)
    if (this.captured) {
      this.log("📜 Scroll detected - releasing controls")
      this.captured = false
      this.controlsLocked = false
      this.disableScrollPrevention()
      document.removeEventListener("click", this.boundHandleOutsideClick)
      document.removeEventListener("scroll", this.boundHandleScroll, true)
      this.updateCaptureIndicator()
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

  async exportFiles(statusCallback = console.log) {
    const exportUrl = this.exportUrlValue
    const updateStatus = (msg) => {
      this.log(msg)
      if (typeof v === 'function') {
        statusCallback(msg)
      }
    }

    if (!exportUrl) return

    try {
      updateStatus("📦 Preparing export...")
      const response = await fetch(exportUrl, {
        method: "POST",
        headers: { "X-CSRF-Token": document.querySelector("meta[name='csrf-token']").content }
      })

      if (!response.ok) {
        throw new Error(`Server returned ${response.status}: ${response.statusText}`)
      }

      const data = await response.json()
      const zipUrl = data.url

      // Create download link
      const a = document.createElement("a")
      a.href = zipUrl
      a.download = `mlx42_block_${this.blockIdValue}.zip`
      a.style.display = "none"
      document.body.appendChild(a)
      a.click()
      document.body.removeChild(a)

      // Release object URL
      updateStatus("✅ Export complete!")
      return zipUrl
    } catch (err) {
      console.error("Export failed", err)
      updateStatus(`❌ Export failed: ${err.message}`)
    }
  }

  async importFiles(event) {
    const file = event.target.files[0]
    if (!file) return

    this.log("📦 Importing files...")

    try {
      // Dynamically load JSZip
      const JSZip = await this.loadJSZip()
      const zip = await JSZip.loadAsync(file)

      // Extract files
      const jsFile = zip.file('mlx42_output.js')
      const wasmFile = zip.file('mlx42_output.wasm')
      const dataFile = zip.file('mlx42_output.data')

      if (!jsFile || !wasmFile) {
        throw new Error('ZIP must contain mlx42_output.js and mlx42_output.wasm')
      }

      this.log("Extracting files...")

      // Convert to blobs
      const jsBlob = await jsFile.async('blob')
      const wasmBlob = await wasmFile.async('blob')
      const dataBlob = dataFile ? await dataFile.async('blob') : null

      // Upload to server
      this.log("Uploading to server...")
      await this.uploadFiles(jsBlob, wasmBlob, dataBlob)

      this.log("✅ Import complete! Refresh to see changes.")

      // Clear the input
      event.target.value = ''

      // Reload the page after a short delay
      setTimeout(() => window.location.reload(), 1500)

    } catch (error) {
      this.log(`❌ Import failed: ${error.message}`)
      console.error('Import error:', error)
      event.target.value = ''
    }
  }

  async uploadFiles(jsBlob, wasmBlob, dataBlob) {
    const formData = new FormData()
    formData.append('js_file', jsBlob, 'mlx42_output.js')
    formData.append('wasm_file', wasmBlob, 'mlx42_output.wasm')
    if (dataBlob) {
      formData.append('data_file', dataBlob, 'mlx42_output.data')
    }

    const documentId = window.location.pathname.split('/')[3]
    const url = `/author/documents/${documentId}/blocks/${this.blockIdValue}/import_mlx42_files`

    const response = await fetch(url, {
      method: 'POST',
      body: formData,
      headers: {
        'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
      }
    })

    if (!response.ok) {
      const error = await response.json()
      throw new Error(error.error || 'Upload failed')
    }

    return response.json()
  }

  async loadJSZip() {
    if (window.JSZip) return window.JSZip

    // Load JSZip from CDN
    return new Promise((resolve, reject) => {
      const script = document.createElement('script')
      script.src = 'https://cdnjs.cloudflare.com/ajax/libs/jszip/3.10.1/jszip.min.js'
      script.onload = () => resolve(window.JSZip)
      script.onerror = () => reject(new Error('Failed to load JSZip'))
      document.head.appendChild(script)
    })
  }
}
