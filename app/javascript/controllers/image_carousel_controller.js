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
    // Check if containerTarget exists (it might not be in the same scope)
    if (!this.hasContainerTarget) {
      console.warn("Image carousel: container target not found")
      return
    }
    const container = this.containerTarget
    const translateX = -this.currentIndex * 100
    container.style.transform = `translateX(${translateX}%)`
    this.updateIndicators()
  }

  updateIndicators() {
    this.indicatorTargets.forEach((indicator, index) => {
      if (index === this.currentIndex) {
        indicator.classList.remove("bg-white/50")
        indicator.classList.add("bg-white")
      } else {
        indicator.classList.remove("bg-white")
        indicator.classList.add("bg-white/50")
      }
    })
  }
}