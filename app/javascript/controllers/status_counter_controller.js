import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['counter']

  connect() {
    this.update();
  }

  update(event) {
    if (!this.hasCounterTarget) return
    const completeCount = this.element.querySelectorAll('[data-selected-item-form-status-value="complete"]').length;
    const savedCount = this.element.querySelectorAll('[data-saved-for-later]').length;

    let text = `${completeCount} ready to submit`;
    if (savedCount > 0) {
      text += ` · ${savedCount} saving for later`;
    }

    this.counterTarget.innerHTML = text;
  }
}
