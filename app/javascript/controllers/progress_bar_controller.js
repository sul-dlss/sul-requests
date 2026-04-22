import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["count", "bar"]
  static values = {
    count: { type: Number, default: 0 },
    limit: { type: Number, default: 0 }
  }

  connect() {
    this.update()
  }

  countValueChanged(e) {
    console.log(this.countValue, e)
    this.update()
  }

  limitValueChanged() {
    this.update()
  }

  get percentage() {
    return this.countValue * 100.0 / this.limitValue;
  }

  get barColor() {
    if (this.percentage >= 100) {
      return 'text-bg-danger'
    } else if (this.percentage >= 75) {
      return 'text-bg-warning'
    } else {
      return 'text-bg-success'
    }
  }

  update() {
    if (this.limitValue === 0) return;

    this.barTarget.style.width = `${this.percentage}%`;
    this.barTarget.classList.remove('text-bg-danger', 'text-bg-warning', 'text-bg-success');
    this.barTarget.classList.add(this.barColor);

    this.countTarget.textContent = this.countValue;
  }
}
