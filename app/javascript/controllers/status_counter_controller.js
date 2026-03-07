import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['counter']

  connect() {
    this.update();
  }

  update(event) {
    const completeCount = this.element.querySelectorAll('[data-selected-item-form-status-value="complete"]').length;
    const draftCount =this.element.querySelectorAll('[data-selected-item-form-status-value="incomplete"]').length;

    this.counterTarget.innerHTML = `${completeCount} complete · ${draftCount} drafts`;
  }
}
