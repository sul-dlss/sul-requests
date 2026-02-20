import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["content"]

  connect() {}

  expandAll(event) {
    event.stopPropagation()
    event.preventDefault()
    this.contentTargets.forEach(el => {
      const bsCollapse = Collapse.getOrCreateInstance(el)
      bsCollapse.show()
    })
  }

  collapseAll(event) {
    event.stopPropagation()
    event.preventDefault()
    this.contentTargets.forEach(el => {
      if (el.classList.contains('show')) {
        const bsCollapse = Collapse.getOrCreateInstance(el)
        bsCollapse.hide()
      }
    })
  }
}
