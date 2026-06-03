import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  disableForm() {
    this.element.querySelector('button').disabled = true;
  }
}
