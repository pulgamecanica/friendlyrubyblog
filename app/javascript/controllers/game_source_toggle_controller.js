import { Controller } from "@hotwired/stimulus"

// game_source_toggle_controller
//
// Toggles between the "git URL" and "zip upload" panels on the arcade
// game submission form based on the selected radio. Nothing more.
export default class extends Controller {
  static targets = ["gitPanel", "zipPanel", "radio"]

  connect() {
    this.sync()
  }

  sync() {
    const selected = this.radioTargets.find((r) => r.checked)?.value || "git"
    this.gitPanelTarget.hidden = selected !== "git"
    this.zipPanelTarget.hidden = selected !== "zip"
  }
}
