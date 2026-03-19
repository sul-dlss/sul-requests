import { Controller } from "@hotwired/stimulus"

// For an input form element put 
export default class extends Controller {
  static targets = ["counter"]

  updateCharCounter(event) {
    const currentChars = event.currentTarget.value.length;
    const maxChars = event.currentTarget.maxLength;
    const charClass = maxChars - currentChars < 10 ? 'text-cardinal' : 'text-body-tertiary';
    this.counterTarget.innerHTML = `${currentChars}/${maxChars}`;
    this.counterTarget.classList = `fs-14 ${charClass}`;
  }
}