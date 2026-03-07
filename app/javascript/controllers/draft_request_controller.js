import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "deleteButton"]

  connect() {
   this.selectForDelete()
  }

  selectForDelete() {
    const selectedDrafts = this.selectTargets.filter(selectTarget => selectTarget.checked)
    this.deleteButtonTarget.innerHTML = "Delete selected (" + selectedDrafts.length + ")"

    if(selectedDrafts.length > 0) {
      this.deleteButtonTarget.disabled = false
    } else {
      this.deleteButtonTarget.disabled = true
    }
  }
}