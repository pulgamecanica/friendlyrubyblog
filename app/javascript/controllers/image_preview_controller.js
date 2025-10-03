import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "currentImage"]

  connect() {
    this.inputTarget.addEventListener("change", this.previewImage.bind(this))
  }

  previewImage(event) {
    const file = event.target.files[0]

    if (file && file.type.startsWith("image/")) {
      const reader = new FileReader()

      reader.onload = (e) => {
        // Hide current image if exists
        if (this.hasCurrentImageTarget) {
          this.currentImageTarget.style.display = "none"
        }

        // Show preview
        this.previewTarget.innerHTML = `
          <div class="relative inline-block">
            <img src="${e.target.result}"
                 class="w-32 h-32 object-cover rounded-lg border border-gray-300"
                 alt="Preview">
            <div class="absolute -top-2 -right-2">
              <span class="bg-green-500 text-white rounded-full px-2 py-1 text-xs font-medium">
                New
              </span>
            </div>
          </div>
        `
        this.previewTarget.style.display = "block"
      }

      reader.readAsDataURL(file)
    } else if (file) {
      // Not an image file
      this.previewTarget.innerHTML = `
        <div class="text-red-500 text-sm">
          Please select a valid image file (PNG, JPG, JPEG)
        </div>
      `
      this.previewTarget.style.display = "block"
    } else {
      // No file selected
      this.previewTarget.style.display = "none"
      if (this.hasCurrentImageTarget) {
        this.currentImageTarget.style.display = "block"
      }
    }
  }
}