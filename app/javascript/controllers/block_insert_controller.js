import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["trigger", "form"]
  static values = {
    position: Number,
    documentId: Number
  }

  connect() {
    this.boundClickOutside = this.handleClickOutside.bind(this)
  }

  disconnect() {
    this.removeGlobalListeners()
  }

  showForm(event) {
    event.preventDefault()
    event.stopPropagation()

    this.triggerTarget.style.display = "none"
    this.formTarget.classList.remove("hidden")

    this.addGlobalListeners()
  }

  cancel(event) {
    event.preventDefault()
    this.hideForm()
  }

  selectType(event) {
    event.preventDefault()
    const blockType = event.currentTarget.dataset.type

    this.createBlock(blockType)
  }

  async createBlock(blockType) {
    const formData = new FormData()
    formData.append("block[type]", blockType)
    formData.append("block[position]", this.positionValue)

    // Set default content based on type
    if (blockType === "MarkdownBlock") {
      formData.append("block[data_markdown]", "# New Section\n\nStart writing here...")
    } else if (blockType === "CodeBlock") {
      formData.append("block[data_language]", "Ruby")
      formData.append("block[data_code]", "# Your code here")
    } else {
      formData.append("block[data_html]", "<p>Your HTML content here</p>")
    }

    try {
      const response = await fetch(`/author/documents/${this.documentIdValue}/blocks`, {
        method: "POST",
        headers: {
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "text/vnd.turbo-stream.html"
        },
        body: formData
      })

      if (response.ok) {
        // Process the turbo stream response
        const text = await response.text()
        Turbo.renderStreamMessage(text)
        this.hideForm()
      } else {
        console.error("Failed to create block", response.status, response.statusText)
      }
    } catch (error) {
      console.error("Error creating block:", error)
    }
  }

  hideForm() {
    this.formTarget.classList.add("hidden")
    this.triggerTarget.style.display = "block"
    this.removeGlobalListeners()
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideForm()
    }
  }

  addGlobalListeners() {
    document.addEventListener("click", this.boundClickOutside)
  }

  removeGlobalListeners() {
    document.removeEventListener("click", this.boundClickOutside)
  }
}