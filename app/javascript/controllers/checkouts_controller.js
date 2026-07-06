import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["renew"]

  renewAll() {
    this.renewTargets.forEach((button) => {
      button.dataset.originalSubmitText = button.innerHTML;
      button.innerHTML = button.dataset.turboSubmitsWith;
    });
  }

  resetRenewAll() {
    this.renewTargets.forEach((button) => {
      if (button.dataset.originalSubmitText) button.innerHTML = button.dataset.originalSubmitText;
    });
  }
}
