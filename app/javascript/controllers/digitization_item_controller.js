import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["status"]

  updateStatus() {
    if (this.emptyFields()) {
      this.statusTarget.classList.remove('bi-check2-circle', 'text-green');
      this.statusTarget.classList.add('bi-circle');
    } else {
      this.statusTarget.classList.remove('bi-circle');
      this.statusTarget.classList.add('bi-check2-circle', 'text-green');
    }
  }


  emptyFields() {
    const formData = new FormData(this.element.closest('form'));
    return Array.from(this.element.querySelectorAll('[required]')).find(x => formData.getAll(x.name).every(x => !x))
  }
}
