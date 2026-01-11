import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["popover", "display", "input"]
  static values = { current: Number }

  toggle() {
    this.popoverTarget.togglePopover()
  }

  pick(event) {
    const value = event.target.dataset.value
    this.inputTarget.value = value
    this.displayTarget.textContent = value
    this.popoverTarget.hidePopover()
    this.element.requestSubmit()
  }
}
