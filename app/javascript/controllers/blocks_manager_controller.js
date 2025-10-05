import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  collapseAll() {
    this.setAllBlocksCollapsed(true)
  }

  expandAll() {
    this.setAllBlocksCollapsed(false)
  }

  setAllBlocksCollapsed(shouldCollapse) {
    // Find all block-editor controllers
    const blockElements = document.querySelectorAll('[data-controller*="block-editor"]')

    blockElements.forEach(element => {
      const controller = this.application.getControllerForElementAndIdentifier(element, "block-editor")

      if (controller && !controller.editingValue) {
        const isCurrentlyCollapsed = controller.collapsedValue

        // Only toggle if current state differs from target state
        if (isCurrentlyCollapsed !== shouldCollapse) {
          controller.toggleCollapse()
        }
      }
    })
  }
}
