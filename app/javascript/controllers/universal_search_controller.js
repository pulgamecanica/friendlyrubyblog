import { Controller } from "@hotwired/stimulus"

// Universal search controller with debouncing, dynamic results, and configurable UI
export default class extends Controller {
  static targets = ["input", "results", "spinner"]
  static values = {
    url: String,                          // Backend search endpoint
    debounce: { type: Number, default: 300 }, // Debounce delay in ms
    minChars: { type: Number, default: 2 },   // Minimum characters to trigger search
    position: { type: String, default: "auto" }, // Results position: left, right, center, auto
    width: { type: String, default: "full" }     // Results width: full, input, custom
  }

  connect() {
    this.debounceTimer = null
    this.abortController = null

    // Close results when clicking outside
    this.boundHandleClickOutside = this.handleClickOutside.bind(this)
    document.addEventListener("click", this.boundHandleClickOutside)
  }

  disconnect() {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }
    if (this.abortController) {
      this.abortController.abort()
    }
    document.removeEventListener("click", this.boundHandleClickOutside)
  }

  // Handle input with debouncing
  search() {
    const query = this.inputTarget.value.trim()

    // Clear existing debounce timer
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer)
    }

    // If query is too short, hide results
    if (query.length < this.minCharsValue) {
      this.hideResults()
      return
    }

    // Show spinner immediately
    this.showSpinner()

    // Debounce the actual search
    this.debounceTimer = setTimeout(() => {
      this.performSearch(query)
    }, this.debounceValue)
  }

  // Perform the actual search
  async performSearch(query) {
    // Cancel previous request if still in flight
    if (this.abortController) {
      this.abortController.abort()
    }

    this.abortController = new AbortController()

    try {
      // Build URL with query params
      const url = new URL(this.urlValue, window.location.origin)
      url.searchParams.set("q", query)

      // Pass through any additional params (like date range)
      const urlParams = new URLSearchParams(window.location.search)
      if (urlParams.has("start_date")) {
        url.searchParams.set("start_date", urlParams.get("start_date"))
      }
      if (urlParams.has("end_date")) {
        url.searchParams.set("end_date", urlParams.get("end_date"))
      }

      const response = await fetch(url, {
        headers: {
          "Accept": "text/vnd.turbo-stream.html",
          "X-CSRF-Token": this.csrfToken
        },
        signal: this.abortController.signal
      })

      if (response.ok) {
        const html = await response.text()
        console.log("Search response received, rendering...")
        await Turbo.renderStreamMessage(html)
        this.showResults()
      }
    } catch (error) {
      if (error.name !== "AbortError") {
        console.error("Search error:", error)
        this.hideResults()
      }
    } finally {
      this.hideSpinner()
    }
  }

  // Handle click outside to close results
  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideResults()
    }
  }

  // Handle keyboard navigation
  keydown(event) {
    if (event.key === "Escape") {
      this.hideResults()
      this.inputTarget.blur()
    }
  }

  // Show results dropdown
  showResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.remove("hidden")
      this.positionResults()
    }
  }

  // Hide results dropdown
  hideResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.classList.add("hidden")
    }
  }

  // Show loading spinner
  showSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.remove("hidden")
    }
  }

  // Hide loading spinner
  hideSpinner() {
    if (this.hasSpinnerTarget) {
      this.spinnerTarget.classList.add("hidden")
    }
  }

  // Position results dropdown based on configuration
  positionResults() {
    if (!this.hasResultsTarget) return

    const position = this.positionValue
    const width = this.widthValue

    // Reset classes
    this.resultsTarget.classList.remove("left-0", "right-0", "left-1/2", "-translate-x-1/2")

    // Apply position
    switch (position) {
      case "left":
        this.resultsTarget.classList.add("left-0")
        break
      case "right":
        this.resultsTarget.classList.add("right-0")
        break
      case "center":
        this.resultsTarget.classList.add("left-1/2", "-translate-x-1/2")
        break
      case "auto":
      default:
        // Auto-detect based on available space
        const rect = this.inputTarget.getBoundingClientRect()
        const spaceRight = window.innerWidth - rect.right
        const spaceLeft = rect.left

        if (spaceRight < 300 && spaceLeft > spaceRight) {
          this.resultsTarget.classList.add("right-0")
        } else {
          this.resultsTarget.classList.add("left-0")
        }
        break
    }

    // Apply width
    if (width === "input") {
      this.resultsTarget.style.width = `${this.inputTarget.offsetWidth}px`
    } else if (width !== "full") {
      this.resultsTarget.style.width = width
    }
  }

  // Clear search
  clear() {
    this.inputTarget.value = ""
    this.hideResults()
    this.inputTarget.focus()
  }

  // Focus input
  focus() {
    this.inputTarget.focus()
  }

  // Get CSRF token
  get csrfToken() {
    return document.querySelector('meta[name="csrf-token"]')?.content
  }
}
