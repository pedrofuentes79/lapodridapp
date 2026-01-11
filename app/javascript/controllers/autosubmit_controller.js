import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["submitter"]
  static values = { delay: Number }

  connect() {
    if (!this.hasDelayValue) this.delayValue = 250
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) clearTimeout(this.timeout)
  }

  schedule(event) {
    // Avoid Turbo re-rendering the rounds frame while a cards-dealt number input is focused,
    // otherwise some browsers will adjust the caret position mid-edit.
    const active = document.activeElement
    if (
      active &&
      active.matches &&
      active.matches("input[type='number'][data-rounds-form-target='cardsInput']")
    ) {
      return
    }

    if (this.timeout) clearTimeout(this.timeout)
    this.timeout = setTimeout(() => this.submit(), this.delayValue)
  }

  submit() {
    // Use the preview submitter (with formaction/formmethod/turbo-frame) so the main form still posts to /games on Create.
    const form = this.element
    if (!form) return

    if (this.hasSubmitterTarget && typeof form.requestSubmit === "function") {
      form.requestSubmit(this.submitterTarget)
      return
    }

    // Fallback for older browsers: click the submitter.
    if (this.hasSubmitterTarget) {
      this.submitterTarget.click()
      return
    }

    // Generic fallback: submit the form itself (used by small Turbo-frame forms like the game status grid cells)
    if (typeof form.requestSubmit === "function") {
      form.requestSubmit()
    } else {
      form.submit()
    }
  }
}


