import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['input', 'show', 'hide']

  async connect() {
    await this.hidePassword();
  }

  async hidePassword() {
    this.inputTarget.setAttribute("type", "password");  // hides content
    this.showTarget.hidden = false;
    this.hideTarget.hidden = true;
  }

  async showPassword() {
    this.inputTarget.setAttribute("type", "text");  // shows content
    this.showTarget.hidden = true;
    this.hideTarget.hidden = false;
  }
}
