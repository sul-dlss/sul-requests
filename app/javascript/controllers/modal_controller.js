import { Controller } from "@hotwired/stimulus"
import { Modal } from "bootstrap"

export default class extends Controller {
  static targets = ["template", "frame"]

  open(event) {
    event.preventDefault()
    event.stopPropagation()

    const containingModal = event.currentTarget.closest('.modal');

    const modal = this.createModal()
    const url = new URL(event.currentTarget.href)

    // append modal=true to the URL so that the server can respond with the appropriate variant
    url.searchParams.set("modal", modal.querySelector("turbo-frame").id)

    modal.querySelector("turbo-frame").src = url.toString()

    if (containingModal) {
      containingModal.classList.add("d-none");
      let backdrop;
      if (containingModal.nextSibling.classList.contains("modal-backdrop")) backdrop = containingModal.nextSibling;
      backdrop?.classList?.add("d-none");

      modal.addEventListener("hidden.bs.modal", () => {
        containingModal.classList.remove("d-none");
        backdrop?.classList?.remove("d-none");
      }, { once: true });
    }
  }

  createModal() {
    const template = this.templateTarget
    const modal = template.content.cloneNode(true).querySelector(".modal")
    document.body.appendChild(modal)
    modal.querySelector("turbo-frame").id = `modal-${Date.now()}`
    const bsModal = new Modal(modal)
    bsModal.show()

    modal.addEventListener("hidden.bs.modal", () => {
      // pause to allow any final actions before removing the modal from the DOM.
      setTimeout(() => {
        bsModal.dispose()
        modal.remove()
      }, 1000)
    })

    return modal;
  }
}
