import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['container', 'items', 'savedItem']

  connect() {
    this.update()
  }

  savedItemTargetConnected() {
    this.update()
  }

  savedItemTargetDisconnected() {
    this.update()
  }

  save(event) {
    event.preventDefault()

    const { id } = event.params
    const formItem = this.formItemFor(id)
    if (!formItem) return

    this.submitSaveForLater(id)
    this.setItemInputsDisabled(id, true)
    this.replaceWithSpinner(formItem, id)
    this.containerTarget.hidden = false
    this.dispatch('changed')
  }

  undo(event) {
    this.removeSavedItem(event, (id) => this.restoreFormItem(id))
  }

  delete(event) {
    this.removeSavedItem(event, (id) => this.removeFormItem(id))
  }

  // Private

  removeSavedItem(event, callback) {
    const li = event.target.closest('[data-content-id]')
    const id = li.dataset.contentId

    li.remove()
    callback(id)
    this.dispatch('changed')
  }

  formItemFor(id) {
    return this.element.querySelector(`[data-content-id="${id}"]:not(.saved-item)`)
  }

  replaceWithSpinner(formItem, id) {
    const titleEl = formItem.querySelector('.selected-item-title').cloneNode(true)
    const spinner = document.getElementById('save-for-later-spinner-template').content.firstElementChild.cloneNode(true)
    spinner.id = `save-for-later-spinner-${id}`
    spinner.dataset.contentId = id
    spinner.prepend(titleEl)
    formItem.insertAdjacentElement('afterend', spinner)
    formItem.classList.add('d-none')
  }

  restoreFormItem(id) {
    const formItem = this.formItemFor(id)
    if (!formItem) return

    formItem.classList.remove('d-none')
    this.setItemInputsDisabled(id, false)
    formItem.querySelectorAll('[data-required-for-submit]').forEach(input => {
      input.dispatchEvent(new Event('input', { bubbles: true }))
    })
  }

  removeFormItem(id) {
    const formItem = this.formItemFor(id)
    if (formItem) formItem.remove()
  }

  setItemInputsDisabled(id, disabled) {
    const form = this.element.closest('form')

    const checkbox = form.querySelector(`[data-item-selector-id-param="${id}"]`)
    if (checkbox) checkbox.disabled = disabled

    form.querySelectorAll(`[name^="patron_request[aeon_item][${id}]"]`).forEach(input => {
      input.disabled = disabled
    })
  }

  async submitSaveForLater(itemId) {
    const form = this.element.closest('form')
    const formData = new FormData(form)
    formData.set('save_for_later_item_id', itemId)

    const response = await fetch('/patron_requests/save_for_later', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body: formData
    })

    if (response.ok) {
      const html = await response.text()
      Turbo.renderStreamMessage(html)
    }
  }

  update() {
    if (!this.hasItemsTarget) return

    this.containerTarget.hidden = this.itemsTarget.children.length === 0
    this.updateCount()
  }

  updateCount() {
    const form = this.element.closest('form')
    const countInput = form?.querySelector('[name="patron_request[saved_for_later_count]"]')
    if (countInput) {
      const total = form.querySelectorAll('[data-save-for-later-target="items"] .saved-item').length
      countInput.value = total
    }
  }
}
