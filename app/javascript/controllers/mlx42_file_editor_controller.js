import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["tabsContainer", "addFileButton", "filesInput", "monacoContainer"]
  static values = {
    blockId: String
  }

  connect() {
    this.files = []
    this.currentFileIndex = 0
    this.monacoController = null

    // Initialize from existing data or create default file
    this.loadFiles()
    this.render()

    // Find Monaco editor controller
    this.findMonacoController()
  }

  loadFiles() {
    // Try to load from hidden input
    if (this.hasFilesInputTarget && this.filesInputTarget.value) {
      try {
        this.files = JSON.parse(this.filesInputTarget.value)
      } catch (e) {
        console.error("Failed to parse files JSON:", e)
        this.files = []
      }
    }

    // If no files exist, create a default main.c
    if (this.files.length === 0) {
      this.files = [{
        filename: "main.c",
        content: "#include <MLX42/MLX42.h>\n\nvoid user_main(int argc, char **argv) {\n  extern mlx_t *mlx;\n  // Your MLX42 code here\n}"
      }]
    }
  }

  findMonacoController() {
    // Wait a bit for Monaco to initialize
    setTimeout(() => {
      const monacoElement = this.monacoContainerTarget.querySelector('[data-controller*="monaco-editor"]')
      if (monacoElement) {
        this.monacoController = this.application.getControllerForElementAndIdentifier(monacoElement, "monaco-editor")

        if (this.monacoController) {
          // Load current file content into Monaco
          this.loadFileIntoMonaco()

          // Listen for Monaco content changes
          this.setupMonacoListener()
        }
      }
    }, 500)
  }

  setupMonacoListener() {
    // Store reference to the textarea to listen for changes
    const textarea = this.monacoContainerTarget.querySelector('textarea[data-monaco-editor-target="textarea"]')
    if (textarea) {
      textarea.addEventListener('input', () => {
        this.saveCurrentFileContent()
      })
    }
  }

  render() {
    this.renderTabs()
    this.saveToHiddenField()
  }

  renderTabs() {
    if (!this.hasTabsContainerTarget) return

    // Clear existing tabs
    this.tabsContainerTarget.innerHTML = ""

    // Render each file tab
    this.files.forEach((file, index) => {
      const tab = this.createTab(file, index)
      this.tabsContainerTarget.appendChild(tab)
    })

    // Add "New File" button - prevent bubbling to block-editor
    const addButton = document.createElement("button")
    addButton.type = "button"
    addButton.className = "px-3 py-1.5 text-xs bg-green-600 hover:bg-green-700 text-white rounded transition-colors whitespace-nowrap"
    addButton.innerHTML = "+ New File"
    addButton.addEventListener("click", (e) => {
      e.stopPropagation()
      this.addFile()
    })
    this.tabsContainerTarget.appendChild(addButton)
  }

  createTab(file, index) {
    const isActive = index === this.currentFileIndex
    const tab = document.createElement("div")
    tab.className = `flex items-center gap-2 px-3 py-1.5 rounded transition-colors cursor-pointer whitespace-nowrap ${
      isActive
        ? "bg-purple-600 text-white"
        : "bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300 hover:bg-gray-300 dark:hover:bg-gray-600"
    }`

    // Filename display (editable on click)
    const filenameSpan = document.createElement("span")
    filenameSpan.textContent = file.filename
    filenameSpan.className = "text-xs font-medium"
    filenameSpan.addEventListener("click", (e) => {
      e.stopPropagation()
      this.editFilename(index)
    })

    // Delete button (only show if more than 1 file)
    let deleteBtn = null
    if (this.files.length > 1) {
      deleteBtn = document.createElement("button")
      deleteBtn.type = "button"
      deleteBtn.innerHTML = "×"
      deleteBtn.className = "text-sm font-bold hover:text-red-500 transition-colors"
      deleteBtn.addEventListener("click", (e) => {
        e.stopPropagation()
        this.deleteFile(index)
      })
    }

    // Tab click to switch file - prevent bubbling to block-editor
    tab.addEventListener("click", (e) => {
      e.stopPropagation()
      if (index !== this.currentFileIndex) {
        this.switchToFile(index)
      }
    })

    tab.appendChild(filenameSpan)
    if (deleteBtn) {
      tab.appendChild(deleteBtn)
    }

    return tab
  }

  switchToFile(index) {
    // Save current file content before switching
    this.saveCurrentFileContent()

    // Switch to new file
    this.currentFileIndex = index
    this.render()
    this.loadFileIntoMonaco()
  }

  loadFileIntoMonaco() {
    if (this.monacoController && this.files[this.currentFileIndex]) {
      const currentFile = this.files[this.currentFileIndex]
      this.monacoController.setValue(currentFile.content || "")

      // Update Monaco language based on file extension
      const extension = currentFile.filename.split('.').pop()
      if (extension === 'h' || extension === 'c') {
        // Monaco is already set to 'c' language, keep it
      }
    }
  }

  saveCurrentFileContent() {
    if (this.monacoController && this.files[this.currentFileIndex]) {
      this.files[this.currentFileIndex].content = this.monacoController.getValue()
      this.saveToHiddenField()
    }
  }

  addFile() {
    // Prompt for filename
    const filename = prompt("Enter filename (e.g., utils.c, header.h):", "new_file.c")
    if (!filename) return

    // Validate filename
    if (!filename.match(/\.(c|h|txt)$/i)) {
      alert("Filename must end with .c, .h, or .txt")
      return
    }

    // Check for duplicate filenames
    if (this.files.some(f => f.filename === filename)) {
      alert("A file with this name already exists!")
      return
    }

    // Add new file
    this.files.push({
      filename: filename,
      content: ""
    })

    // Switch to new file
    this.currentFileIndex = this.files.length - 1
    this.render()
    this.loadFileIntoMonaco()
  }

  deleteFile(index) {
    if (this.files.length <= 1) {
      alert("Cannot delete the last file!")
      return
    }

    const filename = this.files[index].filename
    if (!confirm(`Delete ${filename}?`)) {
      return
    }

    // Remove file
    this.files.splice(index, 1)

    // Adjust current index if needed
    if (this.currentFileIndex >= this.files.length) {
      this.currentFileIndex = this.files.length - 1
    } else if (this.currentFileIndex > index) {
      this.currentFileIndex--
    }

    this.render()
    this.loadFileIntoMonaco()
  }

  editFilename(index) {
    const currentFilename = this.files[index].filename
    const newFilename = prompt("Enter new filename:", currentFilename)

    if (!newFilename || newFilename === currentFilename) return

    // Validate filename
    if (!newFilename.match(/\.(c|h|txt)$/i)) {
      alert("Filename must end with .c, .h, or .txt")
      return
    }

    // Check for duplicate filenames
    if (this.files.some((f, i) => i !== index && f.filename === newFilename)) {
      alert("A file with this name already exists!")
      return
    }

    // Update filename
    this.files[index].filename = newFilename
    this.render()
    this.saveToHiddenField()
  }

  saveToHiddenField() {
    if (this.hasFilesInputTarget) {
      this.filesInputTarget.value = JSON.stringify(this.files)

      // Dispatch change event so Rails form knows it changed
      this.filesInputTarget.dispatchEvent(new Event('input', { bubbles: true }))
    }
  }

  // Public method to get all files
  getFiles() {
    this.saveCurrentFileContent()
    return this.files
  }

  // Prevent clicks from bubbling to block-editor
  preventBubble(event) {
    event.stopPropagation()
  }
}
