import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "editor", "fallbackNotice", "fullscreenButton"]
  static values = {
    language: { type: String, default: "plaintext" },
    minWidth: { type: Number, default: 768 }
  }

  connect() {
    this.editor = null
    this.useMonaco = this.shouldUseMonaco()
    this.isFullscreen = false

    if (this.useMonaco) {
      this.initializeMonaco()
    } else {
      this.showFallback()
    }

    // Listen for window resize
    this.boundHandleResize = this.handleResize.bind(this)
    window.addEventListener("resize", this.boundHandleResize)

    // Listen for theme changes
    this.boundHandleThemeChange = this.handleThemeChange.bind(this)
    this.observeThemeChanges()

    // Listen for ESC key to exit fullscreen
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape)
  }

  disconnect() {
    window.removeEventListener("resize", this.boundHandleResize)
    document.removeEventListener("keydown", this.boundHandleEscape)

    if (this.themeObserver) {
      this.themeObserver.disconnect()
    }

    if (this.editor) {
      this.editor.dispose()
      this.editor = null
    }
  }

  shouldUseMonaco() {
    return window.innerWidth >= this.minWidthValue
  }

  handleResize() {
    const shouldUse = this.shouldUseMonaco()

    if (shouldUse !== this.useMonaco) {
      this.useMonaco = shouldUse

      if (this.useMonaco) {
        this.initializeMonaco()
      } else {
        if (this.editor) {
          // Save content to textarea before disposing
          this.textareaTarget.value = this.editor.getValue()
          this.editor.dispose()
          this.editor = null
        }
        this.showFallback()
      }
    }
  }

  async initializeMonaco() {
    // Hide fallback notice
    if (this.hasFallbackNoticeTarget) {
      this.fallbackNoticeTarget.style.display = "none"
    }

    // Show editor container
    if (this.hasEditorTarget) {
      this.editorTarget.style.display = "block"
    }

    // Show fullscreen button
    if (this.hasFullscreenButtonTarget) {
      this.fullscreenButtonTarget.style.display = "block"
    }

    // Load Monaco Editor from CDN
    if (!window.monaco) {
      await this.loadMonaco()
    }

    // Get current content from textarea
    const currentValue = this.textareaTarget.value

    // Hide the original textarea
    this.textareaTarget.style.display = "none"

    // Determine Monaco language
    const monacoLanguage = this.mapLanguageToMonaco(this.languageValue)

    // Detect theme
    const isDark = this.isDarkTheme()
    const theme = isDark ? "vs-dark" : "vs"

    // Create Monaco Editor
    this.editor = window.monaco.editor.create(this.editorTarget, {
      value: currentValue,
      language: monacoLanguage,
      theme: theme,
      automaticLayout: true,
      minimap: { enabled: false },
      fontSize: 14,
      lineNumbers: "on",
      roundedSelection: true,
      scrollBeyondLastLine: false,
      readOnly: false,
      tabSize: 2,
      insertSpaces: true,
      wordWrap: "on",
      wrappingIndent: "indent",
      folding: true,
      renderLineHighlight: "all",
      padding: { top: 8, bottom: 8 }
    })

    // Sync Monaco content back to textarea
    this.editor.onDidChangeModelContent(() => {
      this.textareaTarget.value = this.editor.getValue()

      // Dispatch input event to notify other controllers (like block-editor)
      this.textareaTarget.dispatchEvent(new Event("input", { bubbles: true }))
    })

    // Set appropriate height
    this.updateEditorHeight()
  }

  showFallback() {
    // Show fallback notice
    if (this.hasFallbackNoticeTarget) {
      this.fallbackNoticeTarget.style.display = "block"
    }

    // Hide editor container
    if (this.hasEditorTarget) {
      this.editorTarget.style.display = "none"
    }

    // Show the original textarea
    this.textareaTarget.style.display = "block"
  }

  async loadMonaco() {
    return new Promise((resolve, reject) => {
      // Load Monaco loader script
      const loaderScript = document.createElement("script")
      loaderScript.src = "https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs/loader.min.js"
      loaderScript.onload = () => {
        // Configure Monaco loader
        window.require.config({
          paths: { vs: "https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.45.0/min/vs" }
        })

        // Load Monaco
        window.require(["vs/editor/editor.main"], () => {
          resolve()
        })
      }
      loaderScript.onerror = reject
      document.head.appendChild(loaderScript)
    })
  }

  mapLanguageToMonaco(language) {
    // Map database language extensions to Monaco language IDs
    const languageMap = {
      "rb": "ruby",
      "js": "javascript",
      "ts": "typescript",
      "py": "python",
      "sh": "shell",
      "bash": "shell",
      "c": "c",
      "cpp": "cpp",
      "html": "html",
      "css": "css",
      "markdown": "markdown",
      "md": "markdown",
      "json": "json",
      "xml": "xml",
      "yaml": "yaml",
      "sql": "sql"
    }

    const normalizedLanguage = language.toLowerCase().trim()
    return languageMap[normalizedLanguage] || "plaintext"
  }

  isDarkTheme() {
    // Check if dark mode is active
    return document.documentElement.classList.contains("dark") ||
           document.body.classList.contains("dark") ||
           window.matchMedia("(prefers-color-scheme: dark)").matches
  }

  handleThemeChange() {
    if (this.editor) {
      const isDark = this.isDarkTheme()
      const theme = isDark ? "vs-dark" : "vs"
      window.monaco.editor.setTheme(theme)
    }
  }

  observeThemeChanges() {
    // Watch for class changes on html/body to detect theme switches
    this.themeObserver = new MutationObserver(() => {
      this.handleThemeChange()
    })

    this.themeObserver.observe(document.documentElement, {
      attributes: true,
      attributeFilter: ["class"]
    })

    this.themeObserver.observe(document.body, {
      attributes: true,
      attributeFilter: ["class"]
    })
  }

  updateEditorHeight() {
    if (!this.editor) return

    if (this.isFullscreen) {
      // Fullscreen mode - use 100vh
      this.editorTarget.style.height = "100vh"
    } else {
      // Default mode - use 90vh
      this.editorTarget.style.height = "90vh"
    }

    // Trigger layout update
    this.editor.layout()
  }

  toggleFullscreen(event) {
    // Prevent event from bubbling up to parent handlers
    if (event) {
      event.stopPropagation()
      event.preventDefault()
    }

    this.isFullscreen = !this.isFullscreen

    if (this.isFullscreen) {
      // Enter fullscreen
      this.element.classList.add("monaco-fullscreen")
      document.body.style.overflow = "hidden"

      // Update button icon
      if (this.hasFullscreenButtonTarget) {
        this.fullscreenButtonTarget.innerHTML = `
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"/>
          </svg>
        `
        this.fullscreenButtonTarget.title = "Exit Fullscreen (ESC)"
      }
    } else {
      // Exit fullscreen
      this.element.classList.remove("monaco-fullscreen")
      document.body.style.overflow = ""

      // Update button icon
      if (this.hasFullscreenButtonTarget) {
        this.fullscreenButtonTarget.innerHTML = `
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"/>
          </svg>
        `
        this.fullscreenButtonTarget.title = "Fullscreen"
      }
    }

    this.updateEditorHeight()
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.isFullscreen) {
      this.toggleFullscreen()
    }
  }

  // Public method to get editor instance (for external access if needed)
  getEditor() {
    return this.editor
  }

  // Public method to set value programmatically
  setValue(value) {
    if (this.editor) {
      this.editor.setValue(value)
    } else {
      this.textareaTarget.value = value
    }
  }

  // Public method to get value
  getValue() {
    if (this.editor) {
      return this.editor.getValue()
    }
    return this.textareaTarget.value
  }
}
