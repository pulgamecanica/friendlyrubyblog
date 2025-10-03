import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  static targets = ["console"]
  static values = { blockId: Number, documentId: Number, executeUrl: String }

  connect() {
    // Set default execute URL if not provided
    if (!this.executeUrlValue) {
      this.executeUrlValue = `/author/documents/${this.documentIdValue}/blocks/${this.blockIdValue}/execute`
    }

    // Setup ActionCable subscription for real-time updates
    this.setupCableConnection()
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  setupCableConnection() {
    const consumer = createConsumer()
    this.subscription = consumer.subscriptions.create(
      {
        channel: "CodeExecutionChannel",
        block_id: this.blockIdValue
      },
      {
        received: (data) => {
          this.handleExecutionResult(data)
        }
      }
    )
  }

  async run(event) {
    event.preventDefault()

    const button = event.currentTarget
    const originalText = button.textContent

    // Show loading state
    button.textContent = "⏳ Running..."
    button.disabled = true

    try {
      // Get the code from the block
      const codeTextarea = this.getCodeTextarea()
      const code = codeTextarea ? codeTextarea.value : ""

      if (!code.trim()) {
        this.showOutput("No code to execute", "error")
        this.restoreButton(button, originalText)
        return
      }

      // Show "queued" state
      this.showOutput("Code execution queued...", "info")

      // Start the async execution
      const response = await fetch(this.executeUrlValue, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': this.getCSRFToken()
        },
        body: JSON.stringify({ code: code })
      })

      const result = await response.json()

      if (response.ok) {
        // Show running state - actual result will come via ActionCable
        this.showOutput("Code is running...", "info")
      } else {
        this.showOutput(result.error || "Failed to start execution", "error")
        this.restoreButton(button, originalText)
      }

    } catch (error) {
      console.error('Code execution error:', error)
      this.showOutput(`Error: ${error.message}`, "error")
      this.restoreButton(button, originalText)
    }

    // Note: Button will be restored when execution completes via ActionCable
  }

  handleExecutionResult(data) {
    const button = this.element.querySelector('[data-action*="run"]')

    if (data.status === 'completed') {
      if (data.output) {
        this.showOutput(data.output, "success")
      } else if (data.error) {
        this.showOutput(data.error, "error")
      } else {
        this.showOutput("Code executed successfully (no output)", "success")
      }
    } else if (data.status === 'failed') {
      this.showOutput(data.error || "Execution failed", "error")
    }

    // Restore button state
    if (button) {
      this.restoreButton(button, "▶ Run Code")
    }
  }

  restoreButton(button, originalText) {
    button.textContent = originalText
    button.disabled = false
  }

  showOutput(text, type = "success") {
    if (!this.hasConsoleTarget) {
      console.error("Console target not found")
      return
    }

    // Update the console section with proper dark theme styling
    let statusClass, statusText
    switch (type) {
      case 'error':
        statusClass = 'text-red-400'
        statusText = '❌ Error'
        break
      case 'info':
        statusClass = 'text-blue-400'
        statusText = '⏳ Running...'
        break
      default:
        statusClass = 'text-green-400'
        statusText = '✅ Output'
    }

    this.consoleTarget.innerHTML = `
      <div class="text-sm font-mono">
        <div class="${statusClass} text-xs mb-2">${statusText}</div>
        <pre class="whitespace-pre-wrap text-gray-100">${this.escapeHtml(text)}</pre>
      </div>
    `
  }

  getCodeTextarea() {
    // Look for code textarea in the same block
    const blockElement = this.element.closest('[data-block-editor-target="content"], turbo-frame')
    return blockElement ? blockElement.querySelector('textarea[name*="data_code"]') : null
  }


  getCSRFToken() {
    const metaTag = document.querySelector('meta[name="csrf-token"]')
    return metaTag ? metaTag.getAttribute('content') : ''
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }
}