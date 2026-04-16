import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";
import DOMPurify from "dompurify";


export default class extends Controller {
  static targets = ["viewModal", "banner", "contents"]
  connect() {
  
  }

  openViewModal(event) {
    // get id of item 
    const itemId = event.currentTarget.dataset.itemId
    this.populateModal(itemId)
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
    const contentsId = 'container-items-' + itemId
    const contentsElement = document.querySelector("#" + contentsId + " ul")
    const contents = Array.from(contentsElement.children).map(contentElement => "<li>" + contentElement.innerHTML + "</li>")
    this.contentsTarget.innerHTML = "<ul class='container-content p-0 m-0'>" + contents.join('') + "</ul>"

  }
}
