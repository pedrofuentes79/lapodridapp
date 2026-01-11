import { Controller } from "@hotwired/stimulus"

// Restore scroll position on Turbo page load
document.addEventListener("turbo:load", () => {
  const params = new URLSearchParams(window.location.search)
  const scrollY = params.get("scrollY")
  if (scrollY) {
    setTimeout(() => {
      window.scrollTo(0, parseInt(scrollY, 10))
    }, 0)
  }
})

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
    const form = this.element
    if (!form) return

    // Update focus to next field in column and calculate scroll position
    const focusInput = form.querySelector("input[name='focus']")
    let scrollY = window.scrollY
    if (focusInput) {
      const nextId = this.nextFieldInColumn(focusInput.value)
      if (nextId) {
        focusInput.value = nextId
        scrollY = this.scrollPositionFor(nextId)
      }
    }

    // Add scrollY to form action URL
    const url = new URL(form.action)
    url.searchParams.set("scrollY", scrollY)
    form.action = url.toString()

    // Use the preview submitter (with formaction/formmethod/turbo-frame) so the main form still posts to /games on Create.
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

  nextFieldInColumn(currentId) {
    // IDs are like: r0-player-asked or r0-player-made
    // Find all inputs with same suffix (asked/made) and get the next one
    const suffix = currentId.endsWith("-asked") ? "-asked" : "-made"
    const inputs = Array.from(document.querySelectorAll(`input[id$="${suffix}"]`))
    const currentIndex = inputs.findIndex(it => it.id === currentId)
    if (currentIndex >= 0 && currentIndex < inputs.length - 1) {
      return inputs[currentIndex + 1].id
    }
    return currentId // Stay on same field if last
  }

  scrollPositionFor(elementId) {
    const element = document.getElementById(elementId)
    if (!element) return window.scrollY

    const rect = element.getBoundingClientRect()
    const margin = 100 // pixels from top of viewport
    return Math.max(0, window.scrollY + rect.top - margin)
  }

  submitOnEnter(event) {
    event.preventDefault()
    this.submit()
  }
}


