import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["appointment"]

  connect() {
    this.subscribeToNewSavedRequests()
  }

  appointmentTargetConnected(el) {
    this.toggleAddItemsButtonState(el)
  }

  subscribeToNewSavedRequests() {
    this.observer = new MutationObserver((mutations) => {
      this.toggleAddItemsButtonState()
    });

    this.observer.observe(document.querySelector("#saved_for_later_aeon_requests_sidebar"), {
      childList: true, subtree: true
    });
  }

  disconnect() {
    this.observer.disconnect();
  }

  toggleAddItemsButtonState(el = this.element) {
    const requestGroups = document.querySelectorAll("#saved_for_later_aeon_requests_sidebar .request-group[data-reading-room-id]")
    const requestGroupReadingRoomIds = Array.from(requestGroups).map(group => group.dataset.readingRoomId);

    el.querySelectorAll(".add-items-button").forEach(button => {
      if (requestGroupReadingRoomIds.includes(button.dataset.readingRoomId)) {
        delete button.dataset.disabled
      } else {
        button.dataset.disabled = true
      }
    });
  }
}
