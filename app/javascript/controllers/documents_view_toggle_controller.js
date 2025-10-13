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
      this.gridButtonTarget.classList.add("text-green-600", "dark:text-green-500")
      this.gridButtonTarget.classList.remove("text-gray-500", "dark:text-gray-600")
      this.tableButtonTarget.classList.remove("text-green-600", "dark:text-green-500")
      this.tableButtonTarget.classList.add("text-gray-500", "dark:text-gray-600")
    } else {
      this.tableViewTarget.classList.remove("hidden")
      this.gridViewTarget.classList.add("hidden")
      this.tableButtonTarget.classList.add("text-green-600", "dark:text-green-500")
      this.tableButtonTarget.classList.remove("text-gray-500", "dark:text-gray-600")
      this.gridButtonTarget.classList.remove("text-green-600", "dark:text-green-500")
      this.gridButtonTarget.classList.add("text-gray-500", "dark:text-gray-600")
    }
  }
}
