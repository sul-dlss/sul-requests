import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["option"]

  connect() {
  }

  optionTargetConnected(option) {
    if (this.element.closest('li').matches(':only-child') && (this.element.querySelector('[selected]')?.value || "") == "") {
      option.selected = true;
    }

    Array.from(this.element.children).sort((a, b) => {
      const aKey = a.dataset.sortKey || "";
      const bKey = b.dataset.sortKey || "";
      return aKey.localeCompare(bKey);
    }).forEach(option => this.element.appendChild(option));

  }
}
