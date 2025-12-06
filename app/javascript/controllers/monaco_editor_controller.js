import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "editor", "fallbackNotice", "fullscreenButton", "floatingPreview"]
  static values = {
    language: { type: String, default: "plaintext" },
    minWidth: { type: Number, default: 768 },
    showPreview: { type: Boolean, default: false },
    previewUrl: String,
    blockId: Number
  }

  connect() {
    this.editor = null
    this.useMonaco = this.shouldUseMonaco()
    this.isFullscreen = false
    this.isDragging = false
    this.isResizing = false

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

    // Listen for ESC key to exit fullscreen (use capture phase to run before block-editor)
    this.boundHandleEscape = this.handleEscape.bind(this)
    document.addEventListener("keydown", this.boundHandleEscape, true) // true = capture phase

    // Check if this is a markdown block and load preview preference
    if (this.languageValue === "markdown") {
      this.loadPreviewPreference()
    }
  }

  disconnect() {
    window.removeEventListener("resize", this.boundHandleResize)
    document.removeEventListener("keydown", this.boundHandleEscape, true) // Remove with capture flag

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

      // Update height based on content (only in non-fullscreen mode)
      if (!this.isFullscreen) {
        this.updateEditorHeight()
      }
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

    // Update floating preview theme if it exists
    this.updateFloatingPreviewTheme()
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
      // Fullscreen mode - use 100vh and full width
      this.editorTarget.style.height = "100vh"
      this.editorTarget.style.width = "100%"
      this.editorTarget.style.maxWidth = "none"
    } else {
      // Inline mode - calculate height based on content
      const contentHeight = this.editor.getContentHeight()
      // Add some padding and cap at reasonable max (600px)
      const height = Math.min(contentHeight + 20, 600)
      this.editorTarget.style.height = `${height}px`
      // Limit width to 100% of parent with max constraint
      this.editorTarget.style.width = "100%"
      this.editorTarget.style.maxWidth = "100%"
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

      // Show floating preview if it's markdown and preview is enabled
      if (this.languageValue === "markdown" && this.showPreviewValue) {
        this.createFloatingPreview()
      }
    } else {
      // Exit fullscreen
      this.element.classList.remove("monaco-fullscreen")
      document.body.style.overflow = ""

      // Reset any inline styles that might have been set
      this.element.style.width = ""
      this.element.style.height = ""
      this.element.style.position = ""
      this.element.style.top = ""
      this.element.style.left = ""
      this.element.style.right = ""
      this.element.style.bottom = ""
      this.element.style.zIndex = ""

      // Update button icon
      if (this.hasFullscreenButtonTarget) {
        this.fullscreenButtonTarget.innerHTML = `
          <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 8V4m0 0h4M4 4l5 5m11-1V4m0 0h-4m4 0l-5 5M4 16v4m0 0h4m-4 0l5-5m11 5l-5-5m5 5v-4m0 4h-4"/>
          </svg>
        `
        this.fullscreenButtonTarget.title = "Fullscreen"
      }

      // Remove floating preview
      this.removeFloatingPreview()

      // Stay in edit mode (inline editor) when exiting fullscreen
      // The editor remains visible and editable

      // Force Monaco to recalculate its layout after exiting fullscreen
      // Multiple attempts with delays to ensure proper resizing
      setTimeout(() => {
        if (this.editor) {
          this.updateEditorHeight()
        }
      }, 50)

      setTimeout(() => {
        if (this.editor) {
          this.updateEditorHeight()
        }
      }, 150)
    }

    // Initial update
    this.updateEditorHeight()
  }

  handleEscape(event) {
    if (event.key === "Escape" && this.isFullscreen) {
      // Stop propagation so block-editor doesn't also handle this ESC
      event.stopPropagation()
      event.preventDefault()
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

  // Load preview preference from block-editor controller's localStorage
  loadPreviewPreference() {
    if (!this.hasBlockIdValue) return

    const storageKey = `block_${this.blockIdValue}_state`
    const savedState = localStorage.getItem(storageKey)

    if (savedState) {
      try {
        const state = JSON.parse(savedState)
        this.showPreviewValue = state.previewVisible !== undefined ? state.previewVisible : true
      } catch (e) {
        this.showPreviewValue = true
      }
    } else {
      this.showPreviewValue = true
    }
  }

  // Create floating draggable/resizable preview
  createFloatingPreview() {
    if (this.floatingPreviewElement) return // Already exists

    // Load saved position/size or use defaults
    const savedPreview = this.loadPreviewPosition()

    // Create preview container
    const preview = document.createElement('div')
    preview.className = 'monaco-floating-preview'
    preview.style.cssText = `
      position: fixed;
      top: ${savedPreview.top}px;
      left: ${savedPreview.left}px;
      width: ${savedPreview.width}px;
      height: ${savedPreview.height}px;
      background: var(--preview-bg, #ffffff);
      border: 2px solid var(--preview-border, #e5e7eb);
      border-radius: 8px;
      box-shadow: 0 20px 25px -5px rgba(0, 0, 0, 0.1), 0 10px 10px -5px rgba(0, 0, 0, 0.04);
      z-index: 9999;
      display: flex;
      flex-direction: column;
      overflow: hidden;
    `

    // Create header (draggable)
    const header = document.createElement('div')
    header.className = 'monaco-floating-preview-header'
    header.style.cssText = `
      padding: 8px 12px;
      background: var(--header-bg, #f9fafb);
      border-bottom: 1px solid var(--header-border, #e5e7eb);
      cursor: move;
      display: flex;
      align-items: center;
      justify-content: space-between;
      user-select: none;
    `

    header.innerHTML = `
      <span style="font-size: 12px; font-weight: 600; color: var(--header-text, #374151); text-transform: uppercase; letter-spacing: 0.05em;">Preview</span>
    `

    // Create content area
    const content = document.createElement('div')
    content.className = 'monaco-floating-preview-content prose prose-neutral dark:prose-invert max-w-none prose-pre:!bg-gray-900 prose-pre:!text-gray-100'
    content.style.cssText = `
      flex: 1;
      overflow-y: auto;
      padding: 16px;
      background: var(--content-bg, #ffffff);
      color: var(--content-text, #111827);
      scroll-behavior: smooth;
    `
    content.innerHTML = '<p style="color: var(--placeholder-text, #9ca3af); font-style: italic;">Preview will appear here...</p>'

    // Add webkit scrollbar styling
    const style = document.createElement('style')
    style.textContent = `
      .monaco-floating-preview-content::-webkit-scrollbar {
        width: 8px;
      }
      .monaco-floating-preview-content::-webkit-scrollbar-track {
        background: var(--scrollbar-track, #f1f1f1);
        border-radius: 4px;
      }
      .monaco-floating-preview-content::-webkit-scrollbar-thumb {
        background: var(--scrollbar-thumb, #888);
        border-radius: 4px;
      }
      .monaco-floating-preview-content::-webkit-scrollbar-thumb:hover {
        background: var(--scrollbar-thumb-hover, #555);
      }
    `
    document.head.appendChild(style)

    // Create resize handle
    const resizeHandle = document.createElement('div')
    resizeHandle.className = 'monaco-floating-preview-resize'
    resizeHandle.style.cssText = `
      position: absolute;
      bottom: 0;
      right: 0;
      width: 20px;
      height: 20px;
      cursor: nwse-resize;
      background: linear-gradient(135deg, transparent 50%, var(--resize-handle, #9ca3af) 50%);
    `

    // Assemble preview
    preview.appendChild(header)
    preview.appendChild(content)
    preview.appendChild(resizeHandle)
    document.body.appendChild(preview)

    this.floatingPreviewElement = preview
    this.floatingPreviewContent = content

    // Prevent clicks inside preview from propagating to block-editor
    preview.addEventListener('mousedown', (e) => {
      e.stopPropagation()
    })
    preview.addEventListener('click', (e) => {
      e.stopPropagation()
    })

    // Set up drag
    this.setupDragging(header, preview)

    // Set up resize
    this.setupResizing(resizeHandle, preview)

    // Apply dark theme if needed
    this.updateFloatingPreviewTheme()

    // Initial render
    this.updateFloatingPreview()

    // Listen to editor changes
    if (this.editor) {
      this.previewUpdateHandler = () => this.updateFloatingPreview()
      this.editor.onDidChangeModelContent(this.previewUpdateHandler)
    }
  }

  removeFloatingPreview() {
    if (this.floatingPreviewElement) {
      // Save position before removing
      this.savePreviewPosition()

      this.floatingPreviewElement.remove()
      this.floatingPreviewElement = null
      this.floatingPreviewContent = null
    }
  }

  setupDragging(header, preview) {
    let startX, startY, initialLeft, initialTop

    const onMouseDown = (e) => {
      this.isDragging = true
      startX = e.clientX
      startY = e.clientY
      initialLeft = preview.offsetLeft
      initialTop = preview.offsetTop

      document.addEventListener('mousemove', onMouseMove)
      document.addEventListener('mouseup', onMouseUp)

      preview.style.cursor = 'grabbing'
      e.preventDefault()
      e.stopPropagation() // Prevent click from reaching block-editor
    }

    const onMouseMove = (e) => {
      if (!this.isDragging) return

      const deltaX = e.clientX - startX
      const deltaY = e.clientY - startY

      preview.style.left = `${initialLeft + deltaX}px`
      preview.style.top = `${initialTop + deltaY}px`
    }

    const onMouseUp = () => {
      this.isDragging = false
      preview.style.cursor = ''
      document.removeEventListener('mousemove', onMouseMove)
      document.removeEventListener('mouseup', onMouseUp)
      this.savePreviewPosition()
    }

    header.addEventListener('mousedown', onMouseDown)
  }

  setupResizing(handle, preview) {
    let startX, startY, initialWidth, initialHeight

    const onMouseDown = (e) => {
      this.isResizing = true
      startX = e.clientX
      startY = e.clientY
      initialWidth = preview.offsetWidth
      initialHeight = preview.offsetHeight

      document.addEventListener('mousemove', onMouseMove)
      document.addEventListener('mouseup', onMouseUp)

      e.preventDefault()
      e.stopPropagation()
    }

    const onMouseMove = (e) => {
      if (!this.isResizing) return

      const deltaX = e.clientX - startX
      const deltaY = e.clientY - startY

      const newWidth = Math.max(300, initialWidth + deltaX)
      const newHeight = Math.max(200, initialHeight + deltaY)

      preview.style.width = `${newWidth}px`
      preview.style.height = `${newHeight}px`
    }

    const onMouseUp = () => {
      this.isResizing = false
      document.removeEventListener('mousemove', onMouseMove)
      document.removeEventListener('mouseup', onMouseUp)
      this.savePreviewPosition()
    }

    handle.addEventListener('mousedown', onMouseDown)
  }

  async updateFloatingPreview() {
    if (!this.floatingPreviewContent || !this.editor) return

    const markdown = this.editor.getValue()

    if (!markdown.trim()) {
      this.floatingPreviewContent.innerHTML = '<p style="color: var(--placeholder-text, #9ca3af); font-style: italic;">Preview will appear here...</p>'
      return
    }

    // Use the preview URL if available
    if (this.hasPreviewUrlValue) {
      try {
        const response = await fetch(this.previewUrlValue, {
          method: "POST",
          headers: {
            "Content-Type": "application/x-www-form-urlencoded",
            "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content
          },
          body: new URLSearchParams({ markdown })
        })

        if (response.ok) {
          const html = await response.text()
          this.floatingPreviewContent.innerHTML = html
        } else {
          this.floatingPreviewContent.innerHTML = '<p style="color: #ef4444;">Preview failed to load</p>'
        }
      } catch (error) {
        console.error("Preview error:", error)
        this.floatingPreviewContent.innerHTML = '<p style="color: #ef4444;">Preview error</p>'
      }
    } else {
      // Fallback: just show the raw markdown
      this.floatingPreviewContent.textContent = markdown
    }
  }

  updateFloatingPreviewTheme() {
    if (!this.floatingPreviewElement) return

    const isDark = this.isDarkTheme()

    if (isDark) {
      this.floatingPreviewElement.style.setProperty('--preview-bg', '#1f2937')
      this.floatingPreviewElement.style.setProperty('--preview-border', '#374151')
      this.floatingPreviewElement.style.setProperty('--header-bg', '#111827')
      this.floatingPreviewElement.style.setProperty('--header-border', '#374151')
      this.floatingPreviewElement.style.setProperty('--header-text', '#f9fafb')
      this.floatingPreviewElement.style.setProperty('--close-btn', '#9ca3af')
      this.floatingPreviewElement.style.setProperty('--content-bg', '#1f2937')
      this.floatingPreviewElement.style.setProperty('--content-text', '#f9fafb')
      this.floatingPreviewElement.style.setProperty('--placeholder-text', '#6b7280')
      this.floatingPreviewElement.style.setProperty('--resize-handle', '#6b7280')
      this.floatingPreviewElement.style.setProperty('--scrollbar-track', '#111827')
      this.floatingPreviewElement.style.setProperty('--scrollbar-thumb', '#4b5563')
      this.floatingPreviewElement.style.setProperty('--scrollbar-thumb-hover', '#6b7280')
    } else {
      this.floatingPreviewElement.style.setProperty('--preview-bg', '#ffffff')
      this.floatingPreviewElement.style.setProperty('--preview-border', '#e5e7eb')
      this.floatingPreviewElement.style.setProperty('--header-bg', '#f9fafb')
      this.floatingPreviewElement.style.setProperty('--header-border', '#e5e7eb')
      this.floatingPreviewElement.style.setProperty('--header-text', '#374151')
      this.floatingPreviewElement.style.setProperty('--close-btn', '#6b7280')
      this.floatingPreviewElement.style.setProperty('--content-bg', '#ffffff')
      this.floatingPreviewElement.style.setProperty('--content-text', '#111827')
      this.floatingPreviewElement.style.setProperty('--placeholder-text', '#9ca3af')
      this.floatingPreviewElement.style.setProperty('--resize-handle', '#9ca3af')
      this.floatingPreviewElement.style.setProperty('--scrollbar-track', '#f1f1f1')
      this.floatingPreviewElement.style.setProperty('--scrollbar-thumb', '#888')
      this.floatingPreviewElement.style.setProperty('--scrollbar-thumb-hover', '#555')
    }
  }

  loadPreviewPosition() {
    const saved = localStorage.getItem('monaco_floating_preview_position')

    if (saved) {
      try {
        return JSON.parse(saved)
      } catch (e) {
        console.error('Failed to load preview position:', e)
      }
    }

    // Default position: bottom right
    return {
      top: window.innerHeight - 420,
      left: window.innerWidth - 520,
      width: 500,
      height: 400
    }
  }

  savePreviewPosition() {
    if (!this.floatingPreviewElement) return

    const position = {
      top: this.floatingPreviewElement.offsetTop,
      left: this.floatingPreviewElement.offsetLeft,
      width: this.floatingPreviewElement.offsetWidth,
      height: this.floatingPreviewElement.offsetHeight
    }

    localStorage.setItem('monaco_floating_preview_position', JSON.stringify(position))
  }
}
