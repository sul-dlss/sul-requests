import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status", "nextButton"]

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


  emptyFields() {
    const formData = new FormData(this.element.closest('form'));
    return Array.from(this.element.querySelectorAll('[required]')).find(x => formData.getAll(x.name).every(x => !x))
  }
}
