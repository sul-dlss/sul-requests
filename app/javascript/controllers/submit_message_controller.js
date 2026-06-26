import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['button', 'message']

  showMessage() {
    this.buttonTarget.hidden = true
    this.messageTarget.classList.toggle('d-none')
  }
  
}