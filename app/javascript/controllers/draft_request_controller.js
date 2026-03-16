import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "deleteButton", "deleteModal", "deleteForm", "selectall"]

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
    const ids = selectedDrafts.map((selectedDraft) => selectedDraft.dataset.id)
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
    const totalCount = selectedDrafts.length
    this.deleteModalTarget.querySelector('.modal-title').innerHTML = this.modalTitle(totalCount)
    // Iterate through the selected drafts, using the attribute to populate the form
    // If the user has not selected all possible draft requests, display descriptions for each item

    let descriptions = ""
    if(this.totalCount < this.totalPossible) {
      descriptions = selectedDrafts.map((selectedDraft, index) => {
        var lastElement = (index == this.totalCount - 1)
        return this.requestDescription(selectedDraft, lastElement) 
      }).join('')
    } else {
      descriptions = this.summaryDescription(selectedDrafts)
    }
    this.deleteModalTarget.querySelector('#request-content').innerHTML = "<div>" + descriptions + "</div>"
  }

  modalTitle(totalCount) {
    const prefix = 'Delete ' + totalCount + ' draft '
    const suffix = (totalCount == 1) ? 'request' : 'requests'
    return prefix + suffix + '?'
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
  
  // handle checking or unchecking the select all checkbox
  toggleSelect(event) {
    this.selectTargets.forEach(selectTarget => {
      selectTarget.checked = event.target.checked
    })

    // We have to call the method handling selection of individual draft checkboxes
    // in this method and not directly associated with the action, b/c
    // we first have to check and uncheck the items before we can count checked values
    // and update the delete button and modal accordingly
    this.selectForDelete()
  }

  // when an individual checkbox is checked or unchecked, we will 
  // update the select all checkbox accordingly
  updateSelectAll() {
    // Check how many items are checked
    const selectedDrafts = this.selectTargets.filter(selectTarget => selectTarget.checked)
    if(selectedDrafts.length == this.totalPossible) {
      this.selectallTarget.checked = true
    } else {
      this.selectallTarget.checked = false
    }
  }


}