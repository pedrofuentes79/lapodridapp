import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "list"]
  static values = { nextIndex: Number }

  connect() {
    this.renumber()
  }

  maybeAdd(event) {
    const isLast = this.inputTargets[this.inputTargets.length - 1] === event.target
    if (!isLast) return

    event.preventDefault()
    if (event.target.value.toString().trim() === "") return
    this.addRow()
  }

  addRow() {
    const idx = this.nextIndexValue

    const wrapper = document.createElement("div")
    wrapper.className = "player-row"
    wrapper.setAttribute("data-player-row", "true")

    const playerInput = document.createElement("div")
    playerInput.className = "player-input"

    const label = document.createElement("label")
    label.setAttribute("for", `players_${idx}_name`)
    label.textContent = `Player ${idx + 1}`

    const input = document.createElement("input")
    input.type = "text"
    input.name = `players[${idx}][name]`
    input.id = `players_${idx}_name`
    input.autocomplete = "off"
    input.setAttribute("data-players-form-target", "input")
    input.setAttribute("data-action", "keydown.enter->players-form#maybeAdd")

    const add = document.createElement("button")
    add.type = "button"
    add.className = "btn btn-small"
    add.textContent = "+"
    add.title = "Add player"
    add.setAttribute("data-add-player-button", "true")
    add.setAttribute("data-action", "players-form#addRow")

    const remove = document.createElement("button")
    remove.type = "button"
    remove.className = "btn btn-danger btn-icon"
    remove.title = "Remove player"
    remove.setAttribute("aria-label", "Remove player")
    remove.innerHTML =
      '<svg viewBox="0 0 24 24" width="16" height="16" aria-hidden="true" focusable="false"><path fill="currentColor" d="M9 3h6l1 2h4v2H4V5h4l1-2Zm1 6h2v10h-2V9Zm4 0h2v10h-2V9ZM7 9h2v10H7V9Zm1 13a2 2 0 0 1-2-2V8h12v12a2 2 0 0 1-2 2H8Z"/></svg>'
    remove.setAttribute("data-action", "players-form#removeRow")

    playerInput.appendChild(label)
    playerInput.appendChild(input)

    wrapper.appendChild(playerInput)
    wrapper.appendChild(add)
    wrapper.appendChild(remove)

    this.listTarget.appendChild(wrapper)
    this.renumber()
    input.focus()
    input.dispatchEvent(new Event("input", { bubbles: true }))
  }

  removeRow(event) {
    event.preventDefault()
    const row = event.target.closest("[data-player-row]")
    if (!row) return

    row.remove()
    if (this.inputTargets.length === 0) {
      this.addRow()
      return
    }

    this.renumber()
    this.inputTargets[this.inputTargets.length - 1]?.dispatchEvent(new Event("input", { bubbles: true }))
  }

  renumber() {
    const rows = Array.from(this.listTarget.querySelectorAll("[data-player-row]"))

    rows.forEach((row, idx) => {
      const label = row.querySelector("label")
      const input = row.querySelector("input[type='text']")
      const add = row.querySelector("[data-add-player-button]")
      if (!label || !input) return

      label.textContent = `Player ${idx + 1}`
      label.setAttribute("for", `players_${idx}_name`)

      input.name = `players[${idx}][name]`
      input.id = `players_${idx}_name`

      if (add) {
        add.style.display = idx === rows.length - 1 ? "" : "none"
      }
    })

    this.nextIndexValue = rows.length
  }
}


