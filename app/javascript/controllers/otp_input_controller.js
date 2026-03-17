import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["digit", "field"]

  connect() {
  }

  fieldTargetConnected() {
    if (this.fieldTarget.value) {
      this.digitTargets.forEach((el, index) => el.value = this.fieldTarget.value[index] || "")
    }
  }

  update() {
    this.fieldTarget.value = this.digitTargets.map(el => el.value).join("")
  }

  paste(event) {
    event.preventDefault()
    const paste = (event.clipboardData || window.clipboardData).getData('text');
    const digits = paste.split("").filter(char => char.match(/\d/)).slice(0, this.digitTargets.length)

    this.digitTargets.forEach((el, index) => el.value = digits[index] || "")

    const firstEmptyDigit = this.digitTargets.find(el => el.value === "");

    (firstEmptyDigit || this.digitTargets[this.digitTargets.length - 1]).focus();
  }

  shift(event) {
    const firstEmptyDigitIndex = this.digitTargets.findIndex(el => el.value === "");
    const thisIndex = this.digitTargets.findIndex(el => el === event.currentTarget);

    if (firstEmptyDigitIndex > 0 && firstEmptyDigitIndex < thisIndex) {
      this.digitTargets[firstEmptyDigitIndex].value = event.currentTarget.value
      event.currentTarget.value = ""
    }
  }

  focus() {
    const firstEmptyDigit = this.digitTargets.find(el => el.value === "");
    const focusedDigit = this.element.querySelector(':focus-within');
    
    // already focused on an empty digit, do not change focus
    if (!firstEmptyDigit && focusedDigit) {
      return
    }

    const lastDigit = this.digitTargets[this.digitTargets.length - 1];

    (firstEmptyDigit || lastDigit).focus()
  }

  keydown(event) {
    if (event.key === "Backspace" || event.key === "Delete") {
      this.erase(event)
    }

    if (event.key == "ArrowLeft") {
      const thisIndex = this.digitTargets.findIndex(el => el === event.currentTarget);
      if (thisIndex > 0) {
        this.digitTargets[thisIndex - 1].focus()
      }
    }
    
    if (event.key == "ArrowRight") {
      const thisIndex = this.digitTargets.findIndex(el => el === event.currentTarget);
      if (thisIndex < this.digitTargets.length - 1) {
        this.digitTargets[thisIndex + 1].focus()
      }
    }
  }

  erase(event) {
    const thisIndex = this.digitTargets.findIndex(el => el === event.currentTarget);

    if (thisIndex === 0) return;

    if (event.currentTarget.value === "") {
      this.digitTargets[thisIndex - 1].value = ""
      this.digitTargets[thisIndex - 1].focus()
    } else {
      event.currentTarget.value = ""
      this.digitTargets[thisIndex - 1].focus()
    }

    this.update();
  }
}
