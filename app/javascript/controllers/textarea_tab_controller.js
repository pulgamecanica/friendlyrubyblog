import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.element.addEventListener("keydown", this.handleKeydown.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this))
  }

  handleKeydown(event) {
    if (event.key === "Tab") {
      event.preventDefault()

      const textarea = this.element
      const start = textarea.selectionStart
      const end = textarea.selectionEnd
      const value = textarea.value

      if (event.shiftKey) {
        // Shift+Tab: Remove indentation
        this.handleShiftTab(textarea, start, end, value)
      } else {
        // Tab: Add indentation
        this.handleTab(textarea, start, end, value)
      }
    }
  }

  handleTab(textarea, start, end, value) {
    const tabChar = "  " // Two spaces (you can change to "\t" for actual tab character)

    if (start === end) {
      // No selection: insert tab at cursor position
      const newValue = value.substring(0, start) + tabChar + value.substring(end)
      textarea.value = newValue
      textarea.setSelectionRange(start + tabChar.length, start + tabChar.length)
    } else {
      // Selection exists: indent all selected lines
      const beforeSelection = value.substring(0, start)
      const selectedText = value.substring(start, end)
      const afterSelection = value.substring(end)

      // Find the start of the first selected line
      const lineStart = beforeSelection.lastIndexOf('\n') + 1
      const fullSelection = value.substring(lineStart, end)

      // Add tab to each line
      const indentedText = fullSelection.split('\n').map(line => tabChar + line).join('\n')

      const newValue = value.substring(0, lineStart) + indentedText + afterSelection
      textarea.value = newValue

      // Update selection to include the added tabs
      const addedChars = indentedText.length - fullSelection.length
      textarea.setSelectionRange(start + tabChar.length, end + addedChars)
    }

    // Trigger input event to notify other controllers (like auto-resize)
    textarea.dispatchEvent(new Event('input', { bubbles: true }))
  }

  handleShiftTab(textarea, start, end, value) {
    const tabChar = "  " // Must match the tab character used in handleTab

    if (start === end) {
      // No selection: remove tab before cursor if it exists
      const beforeCursor = value.substring(0, start)
      const lineStart = beforeCursor.lastIndexOf('\n') + 1
      const currentLine = beforeCursor.substring(lineStart)

      if (currentLine.startsWith(tabChar)) {
        const newValue = value.substring(0, lineStart) + currentLine.substring(tabChar.length) + value.substring(start)
        textarea.value = newValue
        textarea.setSelectionRange(start - tabChar.length, start - tabChar.length)

        // Trigger input event
        textarea.dispatchEvent(new Event('input', { bubbles: true }))
      }
    } else {
      // Selection exists: unindent all selected lines
      const beforeSelection = value.substring(0, start)
      const afterSelection = value.substring(end)

      // Find the start of the first selected line
      const lineStart = beforeSelection.lastIndexOf('\n') + 1
      const fullSelection = value.substring(lineStart, end)

      // Remove tab from each line that starts with it
      const lines = fullSelection.split('\n')
      let removedChars = 0
      const unindentedLines = lines.map(line => {
        if (line.startsWith(tabChar)) {
          removedChars += tabChar.length
          return line.substring(tabChar.length)
        }
        return line
      })

      const unindentedText = unindentedLines.join('\n')
      const newValue = value.substring(0, lineStart) + unindentedText + afterSelection
      textarea.value = newValue

      // Update selection
      const newStart = Math.max(lineStart, start - tabChar.length)
      const newEnd = end - removedChars
      textarea.setSelectionRange(newStart, newEnd)

      // Trigger input event
      textarea.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }
}