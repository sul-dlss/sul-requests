import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["status", "nextButton", "charCounter"]

  connect() {
    this.updateStatus();
  }

  updateStatus() {
    if (this.emptyFields()) {
      this.statusTarget.classList.remove('bi-check2-circle', 'text-green');
      this.statusTarget.classList.add('bi-circle');
      if (this.hasNextButtonTarget) this.nextButtonTarget.disabled = true;
    } else {
      this.statusTarget.classList.remove('bi-circle');
      this.statusTarget.classList.add('bi-check2-circle', 'text-green');
      if (this.hasNextButtonTarget) this.nextButtonTarget.disabled = false;
    }
  }

  updateCharCounter(event) {
    const currentChars = event.currentTarget.value.length;
    const maxChars = event.currentTarget.maxLength;
    const charClass = maxChars - currentChars < 10 ? 'text-cardinal' : 'text-green';
    this.charCounterTarget.innerHTML = `${currentChars}/${maxChars}`;
    this.charCounterTarget.classList = `fs-14 ${charClass}`;
  }

  emptyFields() {
    const formData = new FormData(this.element.closest('form'));
    return Array.from(this.element.querySelectorAll('[required]')).find(x => formData.getAll(x.name).every(x => !x))
  }

  nextItem(event) {
    event.preventDefault();
    event.stopPropagation();

    const currentItem = event.target.closest('[data-content-id]');
    const nextItem = currentItem.nextElementSibling;

    const currentCollapse = currentItem.querySelector('.accordion-collapse');
    const nextCollapse = nextItem?.querySelector('.accordion-collapse');

    if (currentCollapse && nextCollapse) {
      Collapse.getOrCreateInstance(currentCollapse).hide();
      Collapse.getOrCreateInstance(nextCollapse).show();
    }
  }
}
