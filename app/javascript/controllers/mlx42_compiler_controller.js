import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@rails/actioncable"

export default class extends Controller {
  connect() {
    this.subscription = null
    this.consumer = null
  }

  disconnect() {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }
  }

  compile(event) {
    const blockId = event.currentTarget.dataset.blockId
    const documentId = event.currentTarget.dataset.documentId
    const button = event.currentTarget
    const originalText = button.textContent

    button.disabled = true
    button.textContent = "Compiling..."

    // Subscribe to compilation updates
    this.subscribeToCompilation(blockId, button, originalText)

    fetch(`/author/documents/${documentId}/blocks/${blockId}/compile_mlx42`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content,
        "Content-Type": "application/json"
      }
    })
      .then(response => response.json())
      .then(data => {
        if (data.error) {
          console.error("Compilation error:", data.error)
          alert(`Compilation failed: ${data.error}`)
          button.disabled = false
          button.textContent = originalText
        } else {
          console.log("Compilation started:", data.message)
          // Button will be re-enabled when compilation completes via ActionCable
        }
      })
      .catch(error => {
        console.error("Failed to start compilation:", error)
        alert("Failed to start compilation. Check console for details.")
        button.disabled = false
        button.textContent = originalText
      })
  }

  subscribeToCompilation(blockId, button, originalText) {
    if (this.subscription) {
      this.subscription.unsubscribe()
    }

    if (!this.consumer) {
      this.consumer = createConsumer()
    }

    this.subscription = this.consumer.subscriptions.create(
      { channel: "Mlx42CompilationChannel", block_id: blockId },
      {
        received: (data) => {
          console.log("Compilation result received:", data)

          // Re-enable compile button
          if (button) {
            button.disabled = false
            button.textContent = originalText
          }

          // Reload the page to show updated compilation status
          window.location.reload()
        }
      }
    )
  }
}
