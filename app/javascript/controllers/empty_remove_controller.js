import { Controller } from "@hotwired/stimulus"

// Removes the element from the DOM when all its target children are removed.
// Usage: data-controller="empty-remove" with data-empty-remove-target="item" on children.
export default class extends Controller {
  static targets = ["item"]

  itemTargetDisconnected() {
    if (this.itemTargets.length === 0) {
      this.element.remove()
    }
  }
}
