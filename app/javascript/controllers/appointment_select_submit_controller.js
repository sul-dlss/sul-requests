import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  handleSubmit(event) {
    this.disableForm();
    this.showPlaceholder();
  }

  disableForm() {
    this.buttonTarget.classList.add("d-none")
  }

  showPlaceholder() {
    const placeholder = document.createElement("div");
    placeholder.classList.add("d-flex", "align-items-center");
    placeholder.innerHTML = `
      <span class="spinner-border spinner-border-sm me-2" aria-hidden="true"></span>
      <span>Saving appointment...</span>
    `;
    this.element.appendChild(placeholder);
  }
}
