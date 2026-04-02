import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["nextButton"]
  static values = { status: String }

  connect() {
    this.updateStatus();
  }

  updateStatus() {
    if (this.emptyFields()) {
      this.statusValue = 'incomplete';
    } else {
      this.statusValue = 'complete';
    }
  }

  statusValueChanged() {
    if (this.hasNextButtonTarget) {
      this.nextButtonTarget.disabled = this.statusValue === 'incomplete';
    }
    this.dispatch('status-changed', { detail: { status: this.statusValue } });
  }

  emptyFields() {
    const formData = new FormData(this.element.closest('form'));
    return Array.from(this.element.querySelectorAll('[required],[data-required],[data-required-for-submit]')).find(x => formData.getAll(x.name).every(x => !x))
  }

  nextItem(event) {
    event.preventDefault();
    event.stopPropagation();

    const currentItem = event.target.closest('[data-content-id]');
    let nextItem = currentItem.nextElementSibling;
    while (nextItem && !nextItem.offsetParent) {
      nextItem = nextItem.nextElementSibling;
    }

    const currentCollapse = currentItem.querySelector('.accordion-collapse');
    const nextCollapse = nextItem?.querySelector('.accordion-collapse');

    if (currentCollapse && nextCollapse) {
      Collapse.getOrCreateInstance(currentCollapse).hide();
      Collapse.getOrCreateInstance(nextCollapse).show();
    }
  }
}
