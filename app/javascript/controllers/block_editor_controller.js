import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "content", "toolbar", "editor", "preview", "textarea",
    "normalTools", "editTools", "collapseBtn", "previewBtn",
    "layoutBtn", "fadeOverlay", "editorContainer", "updateButton",
    "hiddenSubmit", "submitButton", "interactiveLayout", "singleLayout"
  ]

  static values = {
    editing: { type: Boolean, default: false },
    collapsed: { type: Boolean, default: false },
    previewVisible: { type: Boolean, default: true },
    previewLayout: { type: String, default: "side" }, // "side" or "below"
    blockId: Number,
    previewUrl: String
  }

  connect() {
    this.boundClickOutside = this.handleClickOutside.bind(this)
    this.boundEscapeKey = this.handleEscapeKey.bind(this)
    this.boundInteractiveToggle = this.handleInteractiveToggle.bind(this)

    // Use event delegation to listen for toggle clicks (works even when button is replaced)
    this.element.addEventListener('click', this.boundInteractiveToggle)

    // BRUTE FORCE: Check for unhighlighted code every 500ms
    this.highlightInterval = setInterval(() => {
      this.checkAndFixHighlighting()
    }, 500)

    // Load saved state from localStorage
    this.loadState()

    this.updateToolbar()
    this.updateLayout()
  }

  disconnect() {
    this.removeGlobalListeners()
    this.element.removeEventListener('click', this.boundInteractiveToggle)

    // Clean up interval
    if (this.highlightInterval) {
      clearInterval(this.highlightInterval)
    }
  }

  // Block state management
  enterEditMode() {
    if (this.editingValue) return

    this.editingValue = true
    this.collapsedValue = false // Can't be collapsed in edit mode

    this.addGlobalListeners()
    this.updateToolbar()
    this.updateLayout()

    // Focus the textarea
    if (this.hasTextareaTarget) {
      this.textareaTarget.focus()
    }
  }

  exitEditMode() {
    if (!this.editingValue) return

    this.editingValue = false
    this.removeGlobalListeners()
    this.updateToolbar()
    this.updateLayout()
  }

  toggleCollapse() {
    if (this.editingValue) return // Can't collapse in edit mode

    this.collapsedValue = !this.collapsedValue
    this.saveState()
    this.updateToolbar()
    this.updateLayout()
  }

  // Preview management for markdown blocks
  togglePreview() {
    this.previewVisibleValue = !this.previewVisibleValue
    this.saveState()
    this.updateLayout()
  }

  toggleLayout() {
    const newLayout = this.previewLayoutValue === "side" ? "below" : "side"
    this.previewLayoutValue = newLayout

    // Save globally and apply to all markdown blocks
    localStorage.setItem("markdownPreviewLayout", newLayout)
    this.applyGlobalLayoutClass(newLayout)

    this.updateLayout()
  }

  applyGlobalLayoutClass(layout) {
    // Find the blocks container and add a class
    const blocksContainer = document.getElementById("blocks")
    if (blocksContainer) {
      blocksContainer.classList.remove("markdown-layout-side", "markdown-layout-below")
      blocksContainer.classList.add(`markdown-layout-${layout}`)
    }
  }

  // Event handlers
  handleContentClick(event) {
    if (!this.editingValue) {
      event.preventDefault()
      this.enterEditMode()
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.exitEditMode()
    }
  }

  handleEscapeKey(event) {
    if (event.key === "Escape") {
      this.exitEditMode()
    }
  }

  handleInteractiveToggle(event) {
    // Check if this is actually the toggle button
    const toggleButton = event.target.closest('[type="submit"][class*="bg-blue-"], [type="submit"][class*="bg-gray-"]')
    if (!toggleButton) return

    // Get current state before the toggle happens
    const isCurrentlyInteractive = toggleButton.classList.contains('bg-blue-600')

    // The state will be flipped after the form submission, so we toggle opposite
    const willBeInteractive = !isCurrentlyInteractive

    // Use setTimeout to let the form submission complete first
    setTimeout(() => {
      this.updateInteractiveLayout(willBeInteractive)
    }, 100)
  }

  checkAndFixHighlighting() {
    // Find code elements that have language classes but no highlighting
    const codeElements = this.element.querySelectorAll('pre code[class*="language-"]')

    codeElements.forEach(codeElement => {
      // Check if it's already highlighted (has .token elements)
      if (!codeElement.querySelector('.token')) {
        // Not highlighted - fix it!
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

  updateInteractiveLayout(isInteractive = null) {
    // If not provided, check the current button state
    if (isInteractive === null) {
      const toggleButton = this.element.querySelector('[type="submit"][class*="bg-blue-600"], [type="submit"][class*="bg-gray-300"]')
      if (!toggleButton) return
      isInteractive = toggleButton.classList.contains('bg-blue-600')
    }

    // Toggle between layouts
    if (this.hasInteractiveLayoutTarget && this.hasSingleLayoutTarget) {
      if (isInteractive) {
        this.interactiveLayoutTarget.style.display = ''
        this.singleLayoutTarget.style.display = 'none'
      } else {
        this.interactiveLayoutTarget.style.display = 'none'
        this.singleLayoutTarget.style.display = ''
      }
    }
  }

  // Markdown preview rendering
  async renderPreview() {
    if (!this.hasTextareaTarget || !this.hasPreviewTarget) return

    // Find the content area within the preview (not the whole preview container)
    const previewContent = this.previewTarget.querySelector('.prose')
    if (!previewContent) return

    const markdown = this.textareaTarget.value
    if (!markdown.trim()) {
      previewContent.innerHTML = '<p class="text-gray-400 italic">Preview will appear here...</p>'
      return
    }

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
        previewContent.innerHTML = html
      } else {
        previewContent.innerHTML = '<p class="text-red-400">Preview failed to load</p>'
      }
    } catch (error) {
      console.error("Preview error:", error)
      previewContent.innerHTML = '<p class="text-red-400">Preview error</p>'
    }
  }

  // Textarea auto-resize
  autoResize() {
    if (!this.hasTextareaTarget) return

    const textarea = this.textareaTarget
    textarea.style.height = "auto"
    textarea.style.height = Math.max(textarea.scrollHeight, 120) + "px"
  }

  // Handle form submission from toolbar button
  submitForm(event) {
    event.preventDefault()

    // Trigger the hidden submit button to submit the form
    if (this.hasHiddenSubmitTarget) {
      this.hiddenSubmitTarget.click()
    }
  }

  // Update UI based on current state
  updateToolbar() {
    if (this.hasNormalToolsTarget && this.hasEditToolsTarget) {
      if (this.editingValue) {
        this.normalToolsTarget.style.display = "none"
        this.editToolsTarget.style.display = "flex"
      } else {
        this.normalToolsTarget.style.display = "flex"
        this.editToolsTarget.style.display = "none"
      }
    }

    // Show/hide update button
    if (this.hasUpdateButtonTarget) {
      this.updateButtonTarget.style.display = this.editingValue ? "block" : "none"
    }

    // Update collapse button text
    if (this.hasCollapseBtnTarget) {
      this.collapseBtnTarget.textContent = this.collapsedValue ? "Expand" : "Collapse"
      this.collapseBtnTarget.style.display = this.editingValue ? "none" : "inline-block"
    }

    // Update preview button text
    if (this.hasPreviewBtnTarget) {
      this.previewBtnTarget.textContent = this.previewVisibleValue ? "Hide" : "Show"
    }

    // Update layout button text
    if (this.hasLayoutBtnTarget) {
      this.layoutBtnTarget.textContent = this.previewLayoutValue === "side" ? "Stack" : "Side"
    }
  }

  updateLayout() {
    // Toggle between normal and edit mode - NEVER show both
    if (this.editingValue) {
      // EDIT MODE: Hide content, show editor
      if (this.hasContentTarget) {
        this.contentTarget.style.display = "none"
      }
      if (this.hasEditorTarget) {
        this.editorTarget.style.display = "block"
        this.updateEditorLayout()
      }
      this.autoResize()
    } else {
      // NORMAL MODE: Show content, hide editor
      if (this.hasContentTarget) {
        this.contentTarget.style.display = "block"
      }
      if (this.hasEditorTarget) {
        this.editorTarget.style.display = "none"
      }

      // Handle collapsed state (normal mode only)
      if (this.collapsedValue) {
        // Get toolbar height dynamically
        const toolbarHeight = this.hasToolbarTarget ? this.toolbarTarget.offsetHeight : 200
        this.contentTarget.style.maxHeight = `${toolbarHeight}px`
        this.contentTarget.style.overflow = "hidden"
        if (this.hasFadeOverlayTarget) {
          this.fadeOverlayTarget.style.opacity = "1"
        }
      } else {
        this.contentTarget.style.maxHeight = "none"
        this.contentTarget.style.overflow = "visible"
        if (this.hasFadeOverlayTarget) {
          this.fadeOverlayTarget.style.opacity = "0"
        }
      }
    }
  }

  updateEditorLayout() {
    if (!this.hasEditorContainerTarget) return

    const container = this.editorContainerTarget
    const showPreview = this.previewVisibleValue
    const layout = this.previewLayoutValue

    if (!showPreview) {
      // No preview: hide preview completely
      container.className = "grid grid-cols-1 gap-4"
      if (this.hasPreviewTarget) {
        this.previewTarget.style.display = "none"
      }
    } else {
      // Show preview: arrange based on layout
      if (this.hasPreviewTarget) {
        this.previewTarget.style.display = "block"
      }

      if (layout === "side") {
        // Side by side: two columns
        container.className = "grid grid-cols-1 lg:grid-cols-2 gap-4"
      } else {
        // Stacked: textarea first, then preview below
        container.className = "grid grid-cols-1 gap-4"
      }
    }
  }

  // Global event management
  addGlobalListeners() {
    document.addEventListener("click", this.boundClickOutside)
    document.addEventListener("keydown", this.boundEscapeKey)
  }

  removeGlobalListeners() {
    document.removeEventListener("click", this.boundClickOutside)
    document.removeEventListener("keydown", this.boundEscapeKey)
  }

  // localStorage state management
  getStorageKey() {
    return `block_${this.blockIdValue}_state`
  }

  loadState() {
    if (!this.hasBlockIdValue) return

    // Load individual block state
    const savedState = localStorage.getItem(this.getStorageKey())
    if (savedState) {
      try {
        const state = JSON.parse(savedState)
        if (state.collapsed !== undefined) {
          this.collapsedValue = state.collapsed
        }
        if (state.previewVisible !== undefined) {
          this.previewVisibleValue = state.previewVisible
        }
      } catch (e) {
        console.error("Failed to load block state:", e)
      }
    }

    // Load global layout preference
    const globalLayout = localStorage.getItem("markdownPreviewLayout")
    if (globalLayout) {
      this.previewLayoutValue = globalLayout
      this.applyGlobalLayoutClass(globalLayout)
    }
  }

  saveState() {
    if (!this.hasBlockIdValue) return

    const state = {
      collapsed: this.collapsedValue,
      previewVisible: this.previewVisibleValue
    }

    localStorage.setItem(this.getStorageKey(), JSON.stringify(state))
  }
}