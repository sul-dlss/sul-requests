import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "deleteButton", "deleteModal", "deleteForm"]

  // In case the page saves selections, we want to update the delete button count
  // as well as the delete form
  connect() {
   this.selectForDelete()
  }

  selectForDelete() {
    const selectedDrafts = this.selectTargets.filter(selectTarget => selectTarget.checked)
    this.totalCount = selectedDrafts.length
    this.totalPossible = this.selectTargets.length

    this.deleteButtonTarget.innerHTML = "Delete selected (" + selectedDrafts.length + ")"

    if(selectedDrafts.length > 0) {
      this.deleteButtonTarget.disabled = false
    } else {
      this.deleteButtonTarget.disabled = true
    }
    this.updateModal(selectedDrafts)
  }

  updateModal(selectedDrafts) {
    // Delete any id inputs
    this.clearModalIds()
    // Add new id inputs
    this.addModalIds(selectedDrafts)
    // Add content with details about the selected requests
    this.addDescriptions(selectedDrafts)
  }

  clearModalIds() {
    this.deleteFormTarget.querySelectorAll('input[name="ids[]"').forEach(input => {
      input.remove()
    })
  }

  addModalIds(selectedDrafts) {
    var ids = selectedDrafts.map((selectedDraft) => selectedDraft.dataset.id)
    console.log(ids)
    ids.forEach(id => {
      this.deleteFormTarget.appendChild(this.createIdInput(id))
    })
  }

  createIdInput(id) {
    const idInput = document.createElement("input")
    idInput.type = 'hidden'
    idInput.name = 'ids[]'
    idInput.value = id
    return idInput
  }

  addDescriptions(selectedDrafts) {
    var totalCount = selectedDrafts.length
    this.deleteModalTarget.querySelector('.modal-title').innerHTML = 'Delete ' + totalCount + ' draft requests?'
    // Iterate through the selected drafts, using the attribute to populate the form
    // If the user has not selected all possible draft requests, display descriptions for each item

    var descriptions = ""
    if(this.totalCount < this.totalPossible) {
      descriptions = selectedDrafts.map((selectedDraft, index) => {
        var lastElement = (index == this.totalCount - 1)
        return this.requestDescription(selectedDraft, lastElement) 
      }).join('')
    } else {
      descriptions = this.summaryDescription(selectedDrafts)
    }
    this.deleteModalTarget.querySelector('.modal-body').innerHTML = "<div>" + descriptions + "</div>"
  }

  requestDescription(selectedDraft, lastElement) {
    const data = selectedDraft.dataset
    const borderClass = (lastElement) ? '' : ' border-bottom'
    return "<div class='pt-1 pb-3 modal-draft-request" + borderClass + "'><div class='text-digital-red'>" + data.type + "</div><div class='fw-semibold'>" + selectedDraft.dataset.title + "</div>" +
        "<div>" + data.callnumber + "</div></div>" 
  }

  summaryDescription(selectedDrafts) {
    const digitizationDrafts = selectedDrafts.filter(selectedDraft => selectedDraft.dataset.type == 'Digitization')
    const readingRoomDrafts = selectedDrafts.filter(selectedDraft => selectedDraft.dataset.type != 'Digitization')

    return digitizationDrafts.length + " digitization and " + readingRoomDrafts.length + " reading room use requests"
  }
}