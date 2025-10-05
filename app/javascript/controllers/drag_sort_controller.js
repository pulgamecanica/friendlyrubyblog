import { Controller } from "@hotwired/stimulus"
import Sortable from "sortablejs"

export default class extends Controller {
  static targets = ["container"]
  static values = {
    documentId: Number,
    sortUrl: String
  }

  connect() {
    this.initializeSortable()

    // Listen for turbo stream events that might change the DOM structure
    this.boundTurboStreamRender = this.handleTurboStreamRender.bind(this)
    document.addEventListener("turbo:before-stream-render", this.boundTurboStreamRender)
  }

  initializeSortable() {
    // Safely destroy existing sortable instance
    if (this.sortable) {
      try {
        this.sortable.destroy()
      } catch (error) {
        console.warn("Failed to destroy sortable instance:", error)
      }
      this.sortable = null
    }

    // Get the current container element - use containerTarget if available, otherwise use element itself
    const container = this.hasContainerTarget ? this.containerTarget : this.element

    if (container) {
      this.sortable = Sortable.create(container, {
        animation: 150,
        ghostClass: "opacity-50",
        // chosenClass: "ring-2",
        dragClass: "shadow-lg",
        filter: ".block-insert-zone:not(.block-with-insert .block-insert-zone), [data-block-editor-target='editor']",
        preventOnFilter: false,
        onMove: this.onMove.bind(this),
        onEnd: this.onEnd.bind(this)
      })
    }
  }

  reinitializeSortable() {
    // Just call initializeSortable - the containerTarget getter will automatically
    // find the new DOM element after the turbo frame reload
    this.initializeSortable()
  }

  handleTurboStreamRender(event) {
    // Check if the stream affects our blocks container
    const streamElement = event.target
    if (streamElement && streamElement.target === "blocks") {
      // Use setTimeout to reinitialize after the DOM has been updated
      setTimeout(() => {
        // Double-check that we have a container target before reinitializing
        if (this.hasContainerTarget) {
          this.reinitializeSortable()
        }
      }, 10)
    }
  }

  disconnect() {
    // Safely destroy sortable instance
    if (this.sortable) {
      try {
        this.sortable.destroy()
      } catch (error) {
        console.warn("Failed to destroy sortable instance on disconnect:", error)
      }
      this.sortable = null
    }

    // Remove turbo stream event listener
    if (this.boundTurboStreamRender) {
      document.removeEventListener("turbo:before-stream-render", this.boundTurboStreamRender)
    }
  }

  onMove(evt) {
    const related = evt.related
    const relatedEditor = related.querySelector("[data-block-editor-target='editor']")

    // Prevent dropping on blocks that are in edit mode
    if (relatedEditor && relatedEditor.style.display !== "none") {
      return false
    }

    return true
  }

  async onEnd(evt) {
    // Don't process if item wasn't actually moved
    if (evt.oldIndex === evt.newIndex) {
      return
    }

    // Extract block IDs in new order from block-with-insert containers
    const blockIds = Array.from(this.containerTarget.children)
      .filter(element => element.classList.contains("block-with-insert"))
      .map(container => {
        const turboFrame = container.querySelector("turbo-frame")
        if (turboFrame) {
          // Extract block ID from turbo frame ID (format: "block_123")
          const match = turboFrame.id.match(/block_(\d+)/)
          return match ? match[1] : null
        }
        return null
      })
      .filter(id => id !== null)

    try {
      // Update positions on server
      const response = await fetch(this.sortUrlValue, {
        method: "PATCH",
        headers: {
          "Content-Type": "application/json",
          "X-CSRF-Token": document.querySelector('[name="csrf-token"]').content,
          "Accept": "application/json"
        },
        body: JSON.stringify({
          block_ids: blockIds
        })
      })

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`)
      }

      // Update the UI optimistically without destroying form state
      this.updatePositionDisplays()
      this.updateInsertZonePositions()

    } catch (error) {
      console.error("Failed to update block positions:", error)

      // Revert the DOM change on error
      const item = evt.item
      const container = this.containerTarget
      const children = Array.from(container.children)

      // Remove item from current position
      item.remove()

      // Insert at old position
      if (evt.oldIndex < children.length) {
        container.insertBefore(item, children[evt.oldIndex])
      } else {
        container.appendChild(item)
      }
    }
  }

  updatePositionDisplays() {
    // Update position numbers shown in block toolbars
    const blockContainers = Array.from(this.containerTarget.children)
      .filter(element => element.classList.contains("block-with-insert"))

    blockContainers.forEach((container, index) => {
      const positionElement = container.querySelector("[data-position-display]")
      if (positionElement) {
        positionElement.textContent = `Position ${index + 1}`
      }
    })
  }

  updateInsertZonePositions() {
    // Update insert zone positions based on new block order
    const children = Array.from(this.containerTarget.children)
    let nextPosition = 1

    children.forEach((element) => {
      if (element.classList.contains("block-insert-zone")) {
        // This is the first insert zone (before any blocks)
        const insertController = this.application.getControllerForElementAndIdentifier(element, "block-insert")
        if (insertController) {
          insertController.positionValue = nextPosition
        }
        element.dataset.blockInsertPositionValue = nextPosition
      } else if (element.classList.contains("block-with-insert")) {
        // This is a block container - increment position and update its insert zone
        nextPosition++

        const insertZone = element.querySelector(".block-insert-zone")
        if (insertZone) {
          const insertController = this.application.getControllerForElementAndIdentifier(insertZone, "block-insert")
          if (insertController) {
            insertController.positionValue = nextPosition
          }
          insertZone.dataset.blockInsertPositionValue = nextPosition
        }
      }
    })
  }

  async reloadBlocksFrame() {
    try {
      // Fetch the current page to get updated blocks HTML
      const response = await fetch(window.location.href, {
        headers: {
          "Accept": "text/html",
          "Turbo-Frame": "blocks"
        }
      })

      if (response.ok) {
        const html = await response.text()
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, "text/html")
        const newBlocksFrame = doc.querySelector("turbo-frame#blocks")

        if (newBlocksFrame) {
          const currentFrame = document.querySelector("turbo-frame#blocks")
          if (currentFrame) {
            currentFrame.innerHTML = newBlocksFrame.innerHTML

            // Reinitialize SortableJS with the new DOM structure
            this.reinitializeSortable()
          }
        }
      }
    } catch (error) {
      console.error("Failed to reload blocks frame:", error)
      // Fallback to manual updates
      this.updatePositionDisplays()
      this.updateInsertZonePositions()
    }
  }
}