import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['container', 'items']

  connect() {
    this.update()
  }

  save(event) {
    event.preventDefault()

    const { id } = event.params
    const formItem = this.formItemFor(id)
    if (!formItem) return

    this.postSaveForLater(id)
    this.disableItemInputs(id)
    this.replaceWithSpinner(formItem, id)
    this.containerTarget.hidden = false
    this.dispatch('changed')
  }

  undo(event) {
    event.preventDefault()

    const { transactionNumber } = event.params
    const li = event.target.closest('[data-content-id]')
    const id = li.dataset.contentId

    li.remove()
    this.restoreFormItem(id)
    this.update()
    this.dispatch('changed')

    this.cancelAeonRequest(transactionNumber)
  }

  delete(event) {
    event.preventDefault()

    const { transactionNumber } = event.params
    const li = event.target.closest('[data-content-id]')
    const id = li.dataset.contentId

    li.remove()
    this.removeFormItem(id)
    this.update()
    this.dispatch('changed')

    this.cancelAeonRequest(transactionNumber)
  }

  // Private

  formItemFor(id) {
    return this.element.querySelector(`[data-content-id="${id}"]:not(.saved-item)`)
  }

  replaceWithSpinner(formItem, id) {
    const spinner = document.createElement('div')
    spinner.id = `save-for-later-spinner-${id}`
    spinner.dataset.contentId = id
    spinner.innerHTML = '<span class="spinner-border spinner-border-sm"></span>'
    formItem.insertAdjacentElement('afterend', spinner)
    formItem.classList.add('d-none')
  }

  restoreFormItem(id) {
    const formItem = this.formItemFor(id)
    if (formItem) {
      formItem.classList.remove('d-none')
      this.enableItemInputs(id)
      formItem.querySelectorAll('[data-required-for-submit]').forEach(input => {
        input.dispatchEvent(new Event('input', { bubbles: true }))
      })
    }
  }

  removeFormItem(id) {
    const formItem = this.formItemFor(id)
    if (formItem) formItem.remove()
  }

  disableItemInputs(id) {
    const form = this.element.closest('form')

    const checkbox = form.querySelector(`[data-item-selector-id-param="${id}"]`)
    if (checkbox) checkbox.disabled = true

    form.querySelectorAll(`[name^="patron_request[aeon_item][${id}]"]`).forEach(input => {
      input.disabled = true
    })
  }

  enableItemInputs(id) {
    const form = this.element.closest('form')

    const checkbox = form.querySelector(`[data-item-selector-id-param="${id}"]`)
    if (checkbox) checkbox.disabled = false

    form.querySelectorAll(`[name^="patron_request[aeon_item][${id}]"]`).forEach(input => {
      input.disabled = false
    })
  }

  postSaveForLater(itemId) {
    const form = this.element.closest('form')
    const formData = new FormData(form)
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    const requiredFieldNames = new Set(
      [...form.querySelectorAll('[data-required-for-submit]')].map(el => el.name)
    )

    const body = new URLSearchParams()
    body.set('patron_request[instance_hrid]', formData.get('patron_request[instance_hrid]'))
    body.set('patron_request[origin_location_code]', formData.get('patron_request[origin_location_code]'))
    body.set('patron_request[request_type]', formData.get('patron_request[request_type]'))
    body.set('patron_request[save_for_later_token]', formData.get('save_for_later_token'))
    body.set('patron_request[barcodes][]', itemId)

    const eadUrl = formData.get('patron_request[ead_url]')
    if (eadUrl) body.set('patron_request[ead_url]', eadUrl)

    for (const [key, value] of formData.entries()) {
      if (key.startsWith(`patron_request[aeon_item][${itemId}]`) && !requiredFieldNames.has(key)) {
        body.append(key, value)
      }
    }

    fetch('/patron_requests/save_for_later', {
      method: 'POST',
      headers: { 'X-CSRF-Token': csrfToken },
      body
    })
  }

  cancelAeonRequest(transactionNumber) {
    if (!transactionNumber) return

    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.content

    fetch(`/aeon_requests/${transactionNumber}`, {
      method: 'DELETE',
      headers: { 'X-CSRF-Token': csrfToken, 'Accept': 'text/vnd.turbo-stream.html' }
    })
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
