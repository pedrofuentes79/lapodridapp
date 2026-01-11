import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  submit(event) {
    event.target.blur()
    this.element.requestSubmit()
  }
}
