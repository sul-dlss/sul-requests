import { Controller } from "@hotwired/stimulus"

// For an input form element put 
export default class extends Controller {
  static targets = ["counter"]
  static classes = ["default", "warning"]
  static values = {
    warningThreshold: { type: Number, default: 10 }
  }

  updateCharCounter(event) {
    const currentChars = event.currentTarget.value.length;
    const maxChars = event.currentTarget.maxLength;

    this.counterTarget.innerHTML = `${currentChars}/${maxChars}`;

    if (maxChars - currentChars < this.warningThresholdValue) {
      this.counterTarget.classList.add(this.warningClass);
      this.counterTarget.classList.remove(this.defaultClass);
    } else {
      this.counterTarget.classList.remove(this.warningClass);
      this.counterTarget.classList.add(this.defaultClass);
    }
  }
}
