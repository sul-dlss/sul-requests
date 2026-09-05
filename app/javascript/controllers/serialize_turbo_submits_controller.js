import { Controller } from "@hotwired/stimulus"

// Serializes Turbo form submissions inside this element. While any descendant
// form is in flight, in-scope submit buttons are disabled so the user can only
// ever have one write in flight at a time. This keeps rapid clicks from producing
// concurrent turbo_stream responses that overwrite each other in the DOM.
export default class extends Controller {
  connect() {
    this.inFlight = 0
    this.boundLock = this.lock.bind(this)
    this.boundUnlock = this.unlock.bind(this)
    this.element.addEventListener("turbo:submit-start", this.boundLock)
    this.element.addEventListener("turbo:submit-end", this.boundUnlock)
  }

  disconnect() {
    this.element.removeEventListener("turbo:submit-start", this.boundLock)
    this.element.removeEventListener("turbo:submit-end", this.boundUnlock)
  }

  lock() {
    this.inFlight += 1
    if (this.inFlight === 1) this.toggleButtons(true)
  }

  unlock() {
    this.inFlight = Math.max(0, this.inFlight - 1)
    if (this.inFlight === 0) this.toggleButtons(false)
  }

  toggleButtons(disabled) {
    this.element
      .querySelectorAll('button[type="submit"], button[data-turbo-submits-with]')
      .forEach((el) => { el.disabled = disabled })
  }
}
