import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['currentCount', 'progressBar', 'addButton', 'scheduledItems']

  updateCount(event) {
    const count = this.scheduledItemsTarget.querySelectorAll('li').length
    this.currentCountTarget.innerHTML = count
    const limit = parseInt(this.element.dataset.limit)
    const percentage = count*100/limit
    const newClass = this.newClass(percentage);
    this.progressBarTarget.style.width = `${percentage}%`
    const oldClass = Array.from(this.progressBarTarget.classList).find(c => c.startsWith('text-bg-'))
    this.progressBarTarget.classList.replace(oldClass, newClass)

    if (count >= limit){
      this.addButtonTargets.forEach((elem) => {
        elem.disabled = true;
      })
    }
  }

  newClass(percentage) {
    if (percentage >= 100) return 'text-bg-danger'
    else if (percentage >= 75) return 'text-bg-warning'
    return 'text-bg-success'
  }
}