import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = {
    default: { type: String, default: "light" } // "light" or "dark"
  }

  connect() {
    // Check localStorage first, then use default value
    const savedTheme = localStorage.getItem("theme")
    const theme = savedTheme || this.defaultValue

    this.applyTheme(theme)
  }

  toggle() {
    const currentTheme = document.documentElement.classList.contains("dark") ? "dark" : "light"
    const newTheme = currentTheme === "dark" ? "light" : "dark"

    this.applyTheme(newTheme)
    localStorage.setItem("theme", newTheme)
  }

  applyTheme(theme) {
    if (theme === "dark") {
      document.documentElement.classList.add("dark")
    } else {
      document.documentElement.classList.remove("dark")
    }
  }
}
