import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["gridView", "tableView", "gridButton", "tableButton"]
  static values = {
    storageKey: { type: String, default: "global_view_mode" }
  }

  connect() {
    // Load saved view preference or default to grid
    const savedView = localStorage.getItem(this.storageKeyValue) || "grid"
    this.setView(savedView)
  }

  showGrid(event) {
    event.preventDefault()
    this.setView("grid")
    localStorage.setItem(this.storageKeyValue, "grid")
  }

  showTable(event) {
    event.preventDefault()
    this.setView("table")
    localStorage.setItem(this.storageKeyValue, "table")
  }

  setView(viewMode) {
    if (viewMode === "grid") {
      this.gridViewTarget.classList.remove("hidden")
      this.tableViewTarget.classList.add("hidden")
      this.gridButtonTarget.classList.add("bg-indigo-100", "dark:bg-indigo-900", "text-indigo-700", "dark:text-indigo-300")
      this.gridButtonTarget.classList.remove("text-gray-500", "dark:text-gray-400", "hover:text-gray-700", "dark:hover:text-gray-300")
      this.tableButtonTarget.classList.remove("bg-indigo-100", "dark:bg-indigo-900", "text-indigo-700", "dark:text-indigo-300")
      this.tableButtonTarget.classList.add("text-gray-500", "dark:text-gray-400", "hover:text-gray-700", "dark:hover:text-gray-300")
    } else {
      this.tableViewTarget.classList.remove("hidden")
      this.gridViewTarget.classList.add("hidden")
      this.tableButtonTarget.classList.add("bg-indigo-100", "dark:bg-indigo-900", "text-indigo-700", "dark:text-indigo-300")
      this.tableButtonTarget.classList.remove("text-gray-500", "dark:text-gray-400", "hover:text-gray-700", "dark:hover:text-gray-300")
      this.gridButtonTarget.classList.remove("bg-indigo-100", "dark:bg-indigo-900", "text-indigo-700", "dark:text-indigo-300")
      this.gridButtonTarget.classList.add("text-gray-500", "dark:text-gray-400", "hover:text-gray-700", "dark:hover:text-gray-300")
    }
  }
}
