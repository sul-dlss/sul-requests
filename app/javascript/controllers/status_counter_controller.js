import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['counter']

  connect() {
    this.update();
  }

  update(event) {
    const completeCount = [...this.element.querySelectorAll('[data-selected-item-form-status-value="complete"]')]
      .filter(el => el.offsetParent).length;
    const noun = completeCount === 1 ? 'item' : 'items';

    this.counterTarget.innerHTML = `${completeCount} ${noun} ready to submit`;
  }
}
