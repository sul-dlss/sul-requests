import { Controller } from "@hotwired/stimulus";
import { Modal } from "bootstrap";

export default class extends Controller {
  static targets = ["select", "deleteButton", "deleteModal", "deleteForm",
                     "modalGroup", "modalSummary", "selectall"]

  connect() {
    this.updateDeleteButton()
    this.updateSelectAll()
  }

  updateDeleteButton() {
    const selectedCount = this.selectTargets.filter(t => t.checked).length

    this.deleteButtonTarget.textContent = `Delete selected (${selectedCount})`
    this.deleteButtonTarget.disabled = selectedCount === 0
  }

  openDeleteModal() {
    const selectedIds = this.selectTargets.filter(t => t.checked).map(d => d.dataset.id)
    if (selectedIds.length === 0) return

    const allSelected = selectedIds.length === this.selectTargets.length

    this.setFormIds(selectedIds)
    this.updateModalTitle(selectedIds.length)
    this.updateModalSummary()
    this.updateModalContent(selectedIds, allSelected)

    const modal = Modal.getOrCreateInstance(this.deleteModalTarget)
    modal.show()
  }

  setFormIds(selectedIds) {
    this.deleteFormTarget.querySelectorAll('input[name="ids[]"').forEach(input => input.remove())
    selectedIds.forEach(id => {
      const input = document.createElement("input")
      input.type = 'hidden'
      input.name = 'ids[]'
      input.value = id
      this.deleteFormTarget.appendChild(input)
    })
  }

  updateModalTitle(count) {
    const noun = count === 1 ? 'request' : 'requests'
    this.deleteModalTarget.querySelector('.modal-title').textContent =
      `Delete ${count} saved for later ${noun}?`
  }

  updateModalContent(selectedIds, allSelected) {
    // We show a summary in lieu of individual requests when everything is selected
    this.modalSummaryTarget.hidden = !allSelected

    this.modalGroupTargets.forEach(group => {
      if (allSelected) {
        group.hidden = true
        return
      }

      const items = this.groupItems(group)
      let visibleCount = 0
      items.forEach(item => {
        const visible = selectedIds.includes(item.dataset.requestId)
        item.hidden = !visible
        if (visible) visibleCount++
      })
      group.hidden = visibleCount === 0
    })
  }

  toggleSelectAll(event) {
    this.selectTargets.forEach(t => { t.checked = event.target.checked })
    this.updateDeleteButton()
  }

  updateSelectAll() {
    const selectedCount = this.selectTargets.filter(t => t.checked).length
    const totalPossible = this.selectTargets.length
    this.selectallTarget.checked = totalPossible > 0 && selectedCount === totalPossible
  }

  selectTargetDisconnected() {
    this.updateDeleteButton()
    this.updateSelectAll()
  }

  updateModalSummary() {
    const remainingIds = this.selectTargets.map(t => t.dataset.id)
    let digitization = 0
    let readingRoom = 0

    this.modalGroupTargets.forEach(group => {
      const count = this.groupItems(group)
        .filter(item => remainingIds.includes(item.dataset.requestId)).length
      if (group.dataset.digital === 'true') { digitization += count } else { readingRoom += count }
    })

    const parts = []
    if (digitization > 0) parts.push(`${digitization} digitization`)
    if (readingRoom > 0) parts.push(`${readingRoom} reading room use`)
    this.modalSummaryTarget.textContent = parts.join(' and ') + ' requests'
  }

  // Returns elements with data-request-id for a group.
  // Single-request groups have data-request-id on the group wrapper itself.
  // Multi-item groups have data-request-id on child elements.
  groupItems(group) {
    const children = group.querySelectorAll('[data-request-id]')
    return children.length > 0 ? Array.from(children) : [group].filter(g => g.dataset.requestId)
  }
}
