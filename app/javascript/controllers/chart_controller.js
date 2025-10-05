import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: Object
  }

  connect() {
    // Prevent multiple instances
    if (this.chart) {
      this.chart.destroy()
    }

    // Merge options with responsive defaults
    const defaultOptions = {
      responsive: true,
      maintainAspectRatio: true,
      ...this.optionsValue
    }

    this.chart = new Chart(this.element, {
      type: this.typeValue || "line",
      data: this.dataValue,
      options: defaultOptions
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
      this.chart = null
    }
  }
}
