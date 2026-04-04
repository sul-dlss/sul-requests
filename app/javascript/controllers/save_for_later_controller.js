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

    this.submitSaveForLater(id)
    this.disableItemInputs(id)
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
    this.update()
    this.dispatch('changed')
  }

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

  async submitSaveForLater(itemId) {
    const mainForm = this.element.closest('form')
    const formData = new FormData(mainForm)

    const requiredFieldNames = new Set(
      [...mainForm.querySelectorAll('[data-required-for-submit]')].map(el => el.name)
    )

    const body = new URLSearchParams()
    body.set('patron_request[instance_hrid]', formData.get('patron_request[instance_hrid]'))
    body.set('patron_request[origin_location_code]', formData.get('patron_request[origin_location_code]'))
    body.set('patron_request[request_type]', formData.get('patron_request[request_type]'))
    body.set('patron_request[barcodes][]', itemId)

    const eadUrl = formData.get('patron_request[ead_url]')
    if (eadUrl) body.set('patron_request[ead_url]', eadUrl)

    for (const [key, value] of formData.entries()) {
      if (key.startsWith(`patron_request[aeon_item][${itemId}]`) && !requiredFieldNames.has(key)) {
        body.append(key, value)
      }
    }

    const response = await fetch('/patron_requests/save_for_later', {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content,
        'Accept': 'text/vnd.turbo-stream.html'
      },
      body
    })

    if (response.ok) {
      const html = await response.text()
      this.processTurboStream(html)
      this.update()
    }
  }

  processTurboStream(html) {
    const fragment = document.createElement('template')
    fragment.innerHTML = html

    fragment.content.querySelectorAll('turbo-stream').forEach(stream => {
      const action = stream.getAttribute('action')
      const target = document.getElementById(stream.getAttribute('target'))
      if (!target) return

      if (action === 'remove') target.remove()
      if (action === 'append') target.append(stream.querySelector('template').content.cloneNode(true))
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
