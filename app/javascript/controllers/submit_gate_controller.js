import { Controller } from "@hotwired/stimulus"

// Disables a form's submit button while it is invalid.
// The button starts enabled in the markup so the form still works without JS.
export default class extends Controller {
  static targets = ["submit"]

  connect() {
    this.toggle()
  }

  toggle() {
    this.submitTarget.disabled = !this.element.checkValidity()
  }
}
