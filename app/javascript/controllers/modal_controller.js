import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["frame"]

  frameTargetConnected() {
    this.modal = new Modal(this.frameTarget)
  }

  frameTargetDisconnected() {
    this.modal.dispose()
    this.modal = null
  }

  open(event) {
    event.preventDefault()
    event.stopPropagation()
    this.modal.show()
    const url = new URL(event.currentTarget.href)

    // append modal=true to the URL so that the server can respond with the appropriate variant
    url.searchParams.set("modal", "true")

    this.frameTarget.querySelector("turbo-frame").src = url.toString()
  }
}
