import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  showSubmitsWith() {
    this.buttonTarget.dataset.originalSubmitText = this.buttonTarget.innerHTML;
    this.buttonTarget.innerHTML = this.buttonTarget.dataset.turboSubmitsWith;
  }

  hideSubmitsWith() {
    if (this.buttonTarget.dataset.originalSubmitText) this.buttonTarget.innerHTML = this.buttonTarget.dataset.originalSubmitText;
  }
}
