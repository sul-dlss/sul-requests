import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['counter']

  connect() {
    this.update();
  }

  update(event) {
    if (!this.hasCounterTarget) return
    const completeCount = this.element.querySelectorAll('[data-selected-item-form-status-value="complete"]').length;
    const incompleteCount = this.element.querySelectorAll('[data-selected-item-form-status-value="incomplete"]').length;
    const savedCount = this.element.querySelectorAll('[data-saved-for-later]').length;

    let text = `${completeCount} ready to submit`;

    if (completeCount == 0 && incompleteCount == 0 && savedCount > 0) {
      text = `${savedCount} saved for later`;
    }

    this.counterTarget.innerHTML = text;
  }
}
