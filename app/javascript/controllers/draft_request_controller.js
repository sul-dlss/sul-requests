import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select", "deleteButton", "deleteModal", "deleteForm", "selectall"]

  // In case the page saves selections, we want to update the delete button count
  // as well as the delete form
  connect() {
   this.selectForDelete()
   this.updateSelectAll()
  }

  // Based on the number of selected checkboxes, updates 
  // the text in the bulk delete button, disables or enables
  // that button, and updates the information about selected
  // drafts in the modal
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
    let groupedRequests = this.groupRequests(selectedDrafts)
    let descriptions = ""
    if(this.totalCount < this.totalPossible) {
      descriptions = this.groupedDescriptions(groupedRequests)
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

  // group draft requests by type and title
  groupRequests(selectedDrafts) {
    // Structure = { type: { title: [ request 1, request 2] }  }
    let groupedRequests = {}
    selectedDrafts.forEach(selectedDraft => {
      let data = selectedDraft.dataset
      let type = data.type
      let title = data.title
      if(! (type in groupedRequests)) {
        groupedRequests[type] = {}
      }

      if(! (title in groupedRequests[type])) {
        groupedRequests[type][title] = []
      }

      groupedRequests[type][title].push(selectedDraft)
    })
    return groupedRequests
  }

  // Group descriptions by type and title
  groupedDescriptions(groupedRequests) {
    let descriptions = []
    let counter = 1
    Object.keys(groupedRequests).forEach(type => {
      Object.keys(groupedRequests[type]).forEach(title => {
        let requests = groupedRequests[type][title]
        descriptions.push(this.singleGroupDescription(requests, type, title, (counter == this.totalCount)))
        counter += 1
      })
    })
    return descriptions.join('')
  }

  // For a single grouped display -> display type, then title, and callnumber
  singleGroupDescription(groupedSelectedDrafts, type, title, lastElement) {
    const borderClass = (lastElement) ? '' : ' border-bottom'
    return "<div class='pt-1 pb-3 modal-draft-request" + borderClass + "'><div class='text-digital-red'>" + type + "</div><div class='fw-semibold'>" + title + "</div>" +
        "<div>" + this.groupCallnumber(groupedSelectedDrafts) + "</div>" + this.groupedItems(groupedSelectedDrafts) + "</div>" 
  }

  groupCallnumber(groupedSelectedDrafts) {
    const data = groupedSelectedDrafts[0].dataset
    const prefix = "Call number: "
    // if EAD present, we will return that number for call number display
    if(data.ead !== "") {
      return prefix + data.ead
    }

    // if there is only one item, we should return that call number
    if(groupedSelectedDrafts.length == 1) {
      return prefix + data.callnumber
    }

    // otherwise keep this string empty
    return ""
  }

  groupedItems(groupedSelectedDrafts) {
    if(groupedSelectedDrafts.length == 1) {
      return ""
    } 

    const items = groupedSelectedDrafts.map((selectedDraft) => {
      return '<span class="p-1 bg-fog-light fw-semibold">' + this.callnumberContent(selectedDraft) + '</span>'
    }).join('')

    return "<div class='d-flex flex-row gap-3'>" + items + "</div>"
  }

  // We want to display a callnumber  > volume display if this exists
  // otherwise we will use the callnumber 
  callnumberContent(selectedDraft) {
    const data = selectedDraft.dataset
    const callnumber = data.callnumber
    const ead = data.ead
    let prefix = ""
    if(data.container != "") {
      const container = data.container
      if(ead != "" && callnumber.startsWith(ead)) {
        // Remove the ead portion from the callnumber and display that with a separator
        prefix = callnumber.slice(ead.length) + " > "
      }
      return prefix + container
    }
    return selectedDraft.dataset.callnumber 
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

    // if there are no draft requests on the page, leave the checkbox unchecked
    // otherwise, if the total number of drafts = total selected, have the checkbox be checked
    if ((this.totalPossible > 0) && (selectedDrafts.length == this.totalPossible)) {
      this.selectallTarget.checked = true
    } else {
      this.selectallTarget.checked = false
    }
  }

  // When any of the draft requests are deleted, whether individually or via bulk delete,
  // we want the new number of items to be calculated.
  // Also, this will update the select all checkbox
  selectTargetDisconnected() {
    this.selectForDelete()
    this.updateSelectAll()
  }

}