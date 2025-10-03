import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container", "indicator"]
  static values = { count: Number }

  connect() {
    this.currentIndex = 0
    this.updateIndicators()
  }

  previous() {
    if (this.currentIndex > 0) {
      this.currentIndex--
    } else {
      this.currentIndex = this.countValue - 1
    }
    this.updateCarousel()
  }

  next() {
    if (this.currentIndex < this.countValue - 1) {
      this.currentIndex++
    } else {
      this.currentIndex = 0
    }
    this.updateCarousel()
  }

  goTo(event) {
    this.currentIndex = parseInt(event.target.dataset.index)
    this.updateCarousel()
  }

  updateCarousel() {
    const container = this.containerTarget
    const translateX = -this.currentIndex * 100
    container.style.transform = `translateX(${translateX}%)`
    this.updateIndicators()
  }

  updateIndicators() {
    this.indicatorTargets.forEach((indicator, index) => {
      if (index === this.currentIndex) {
        indicator.classList.remove("bg-gray-300")
        indicator.classList.add("bg-gray-600")
      } else {
        indicator.classList.remove("bg-gray-600")
        indicator.classList.add("bg-gray-300")
      }
    })
  }
}