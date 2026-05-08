import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['input']
  updateInput(e) {
    this.inputTarget.value = e.currentTarget.parentElement.dataset.value;
    this.element.querySelector('button').disabled = true;
  }
}