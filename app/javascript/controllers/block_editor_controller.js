import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "content", "toolbar", "editor", "preview", "textarea",
    "normalTools", "editTools", "collapseBtn", "previewBtn",
    "layoutBtn", "fadeOverlay", "editorContainer", "updateButton",
    "hiddenSubmit", "submitButton"
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
    this.updateToolbar()
    this.updateLayout()
  }

  disconnect() {
    this.removeGlobalListeners()
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
    this.updateLayout()
  }

  // Preview management for markdown blocks
  togglePreview() {
    this.previewVisibleValue = !this.previewVisibleValue
    this.updateLayout()
  }

  toggleLayout() {
    this.previewLayoutValue = this.previewLayoutValue === "side" ? "below" : "side"
    this.updateLayout()
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
        this.contentTarget.style.maxHeight = "200px"
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

  // Value change observers
  editingValueChanged() {
    this.updateToolbar()
    this.updateLayout()
  }

  collapsedValueChanged() {
    this.updateToolbar()
    this.updateLayout()
  }

  previewVisibleValueChanged() {
    this.updateToolbar()
    this.updateLayout()
  }

  previewLayoutValueChanged() {
    this.updateToolbar()
    this.updateLayout()
  }
}