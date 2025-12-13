import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["cardsInput", "list"]
  static values = { nextIndex: Number }

  connect() {
    this.resetNextIndex()
  }

  cardsInputTargetConnected() {
    this.resetNextIndex()
  }

  resetNextIndex() {
    this.nextIndexValue = this.cardsInputTargets.length
  }

  maybeAdd(event) {
    const isLast = this.cardsInputTargets[this.cardsInputTargets.length - 1] === event.target
    if (!isLast) return

    event.preventDefault()
    this.addRow()
  }

  addRow() {
    const idx = this.nextIndexValue

    const row = document.createElement("div")
    row.className = "round-row"

    const roundInput = document.createElement("div")
    roundInput.className = "round-input"

    const cardsField = document.createElement("div")
    cardsField.className = "field"

    const cardsLabel = document.createElement("label")
    cardsLabel.setAttribute("for", `rounds_${idx}_cards_dealt`)
    cardsLabel.textContent = `Round ${idx + 1} - cards dealt`

    const cardsInput = document.createElement("input")
    cardsInput.type = "number"
    cardsInput.min = "0"
    cardsInput.name = `rounds[${idx}][cards_dealt]`
    cardsInput.id = `rounds_${idx}_cards_dealt`
    cardsInput.setAttribute("data-rounds-form-target", "cardsInput")
    cardsInput.setAttribute("data-action", "keydown.enter->rounds-form#maybeAdd")

    const hint = document.createElement("div")
    hint.className = "hint"
    hint.textContent = "Max: —"

    cardsField.appendChild(cardsLabel)
    cardsField.appendChild(cardsInput)
    roundInput.appendChild(cardsField)
    roundInput.appendChild(hint)

    const trumpField = document.createElement("div")
    trumpField.className = "round-trump"

    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = `rounds[${idx}][has_trump]`
    hidden.value = "0"

    const checkbox = document.createElement("input")
    checkbox.type = "checkbox"
    checkbox.name = `rounds[${idx}][has_trump]`
    checkbox.id = `rounds_${idx}_has_trump`
    checkbox.value = "1"
    checkbox.checked = true

    const checkboxLabel = document.createElement("label")
    checkboxLabel.setAttribute("for", `rounds_${idx}_has_trump`)
    checkboxLabel.textContent = "Has trump"

    trumpField.appendChild(hidden)
    trumpField.appendChild(checkbox)
    trumpField.appendChild(checkboxLabel)

    row.appendChild(roundInput)
    row.appendChild(trumpField)

    this.listTarget.appendChild(row)
    this.resetNextIndex()

    cardsInput.focus()
    cardsInput.dispatchEvent(new Event("input", { bubbles: true }))
  }
}


