import { Controller } from "@hotwired/stimulus"
import { Alert } from "bootstrap"

export default class extends Controller {
  static values = {
    key: String
  }

  connect() {
    if (sessionStorage.getItem(this.keyValue)) {
      this.element.classList.add('d-none');
    }
  }

  dismiss() {
    sessionStorage.setItem(this.keyValue, true);
    new Alert(this.element).close();
  }
}
