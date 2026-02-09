import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ["content"]

  connect() {}

  expandAll(event) {
    event.preventDefault()
    this.contentTargets.forEach(el => {
      const bsCollapse = Collapse.getOrCreateInstance(el)
      bsCollapse.show()
    })
  }

  collapseAll(event) {
    event.preventDefault()
    this.contentTargets.forEach(el => {
      const bsCollapse = Collapse.getOrCreateInstance(el)
      bsCollapse.hide()
    })
  }
}
