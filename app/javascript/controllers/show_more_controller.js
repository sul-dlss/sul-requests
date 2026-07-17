import { Controller } from "@hotwired/stimulus"
import scrollIntoView from 'scroll-into-view-if-needed';

export default class extends Controller {
  static targets = ["list", "button"]
  static values = { expanded: { type: Boolean, default: false }, previewCount: { type: Number, default: 3 } }

  connect() {
    this.updateList();
  }

  expandedValueChanged() {
    this.updateList();
  }

  toggle() {
    this.expandedValue = !this.expandedValue;
  }

  updateList() {
    if (!this.hasListTarget || !this.hasButtonTarget) return;

    if (this.listTarget.children.length <= this.previewCountValue) {
      this.buttonTarget.classList.add("d-none");
    }

    if (this.expandedValue) {
      Array.from(this.listTarget.children).forEach((child) => child.classList.remove("d-none"));
      this.buttonTarget.setAttribute("aria-expanded", "true");
      const currentContent = this.buttonTarget.innerHTML;
      this.buttonTarget.innerHTML = this.buttonTarget.dataset.content;
      this.buttonTarget.dataset.content = currentContent;
    } else {
      Array.from(this.listTarget.children).forEach((child, index) => {
        if (index >= this.previewCountValue) {
          child.classList.add("d-none");
        }
      });
      this.buttonTarget.setAttribute("aria-expanded", "false");
      const currentContent = this.buttonTarget.innerHTML;
      this.buttonTarget.innerHTML = this.buttonTarget.dataset.content;
      this.buttonTarget.dataset.content = currentContent;
      scrollIntoView(this.element.closest('.card') || this.element, { behavior: 'smooth', block: 'start', scrollMode: 'if-needed' });
    }
  }
}
