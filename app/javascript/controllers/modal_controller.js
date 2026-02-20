import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["frame"]

  connect() {
    this.modal = new Modal(this.element)

    this.frameTarget.addEventListener("turbo:frame-load", () => {
      this.modal.show()
    })
  }
}
