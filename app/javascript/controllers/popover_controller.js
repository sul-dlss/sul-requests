import { Controller } from "@hotwired/stimulus"
import { Popover } from "bootstrap"

export default class extends Controller {
  connect() {
    this.popover = new Popover(this.element)
  }

  disconnect() {
    this.popover.dispose()
  }

  hide() {
    this.popover.hide()
  }

  hideOutside(event) {
    if (!this.element.contains(event.target)) this.hide()
  }
}
