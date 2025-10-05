import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["expandable", "toggleButton"]

  toggle(event) {
    const button = event.currentTarget
    const seriesId = button.dataset.seriesId
    const expandable = this.expandableTargets.find(el => el.dataset.seriesId === seriesId)
    const svg = button.querySelector("svg")

    if (expandable) {
      expandable.classList.toggle("hidden")

      // Rotate the arrow icon
      if (expandable.classList.contains("hidden")) {
        svg.style.transform = "rotate(0deg)"
      } else {
        svg.style.transform = "rotate(90deg)"
      }
    }
  }
}
