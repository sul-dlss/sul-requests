import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import DOMPurify from "dompurify";


export default class extends Controller {
  static targets = ["viewModal", "banner", "contents", "displayButton"]

  displayButtonTargetConnected(targetElement) {
    if (this.contentsFor(targetElement.dataset.itemId)) {
      targetElement.classList.remove("d-none")
    }
  }
  
  openViewModal(event) {
    // Without this, clicking the button that triggers the event may lead to a form submission
    event.preventDefault();
    // get id of item 
    const itemId = event.currentTarget.dataset.itemId
    // populate the container contents modal using information about this element
    this.populateModal(itemId)
    // show the modal
    const modal = Modal.getOrCreateInstance(this.viewModalTarget)
    modal.show()
  }

  // populate the content of the modal
  populateModal(itemId) {
    const containerElement = document.querySelector("#" + itemId)
    // Add title to the banner
    const modalTitle = this.mapModalTitle(containerElement.dataset.itemSelectorTitlePartsParam)
    this.bannerTarget.innerHTML = modalTitle
    // Copy contents of container to the body
    this.addContents(itemId)
  }

  // Generate the title for the modal for v
  mapModalTitle(titleParts) {
    return JSON.parse(titleParts).filter(e => e?.trim())
      .map(e => DOMPurify.sanitize(e))
      .join('<i class="bi bi-chevron-right mx-1"></i>')
  }

  // Based on the item id, get the appropriate item selection element
  addContents(itemId) {
    const clone = this.contentsFor(itemId).cloneNode(true)
    clone.className = "container-content list-unstyled p-0 m-0"
    this.contentsTarget.replaceChildren(clone)
  }

  contentsFor(itemId) {
    return document.getElementById("container-items-" + itemId)?.querySelector('.container-content')
  }
}
