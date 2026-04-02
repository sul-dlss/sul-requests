import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['container', 'items']

  connect() {
    this.update()
  }

  save(event) {
    event.preventDefault()

    const { id } = event.params
    const formItem = this.element.querySelector(`[data-content-id="${id}"]`)
    if (!formItem) return

    this.clearRequiredInputs(formItem)
    formItem.classList.add('d-none')
    this.itemsTarget.appendChild(this.makeSavedItem(formItem))
    this.update();
    this.dispatch('changed')
  }

  restore(event) {
    event.preventDefault()

    const { id } = event.params

    this.removeSavedItem(id)
    this.restoreFormItem(id)
    this.update();
    this.dispatch('changed')
  }

  hideWhenEmpty(event) {
    requestAnimationFrame(() => {
      if (this.itemsTarget.children.length === 0) {
        this.containerTarget.hidden = true
      }
    })
  }

  clearRequiredInputs(el) {
    el.querySelectorAll('[data-required-for-submit]').forEach(input => {
      input.value = ''
      input.dispatchEvent(new Event('input', { bubbles: true }))
    })
    el.setAttribute('data-saved-for-later', '')
  }

  removeSavedItem(id) {
    const savedItem = this.itemsTarget.querySelector(`[data-content-id="${id}"]`)
    if (savedItem) savedItem.remove()
  }

  restoreFormItem(id) {
    const formItem = this.element.querySelector(`[data-content-id="${id}"][data-saved-for-later]`)
    if (formItem) {
      formItem.removeAttribute('data-saved-for-later')
      formItem.classList.remove('d-none')
      formItem.querySelectorAll('[data-required-for-submit]').forEach(input => {
        input.dispatchEvent(new Event('input', { bubbles: true }))
      })
    }
  }

  makeSavedItem(formItem) {
    const id = formItem.dataset.contentId
    const title = formItem.querySelector('.selected-item-title')

    const li = document.createElement('li')
    li.classList.add('d-flex', 'justify-content-between', 'saved-item', 'border-bottom', 'py-1')
    li.dataset.contentId = id

    const titleClone = title.cloneNode(true)
    titleClone.classList.remove('fw-semibold')

    li.appendChild(titleClone)
    li.insertAdjacentHTML('beforeend', `
    <div>
      <a href="#" class="su-underline me-1 fs-14"
         data-action="save-for-later#restore"
         data-save-for-later-id-param="${id}">Undo</a>
      <button class="btn btn-link p-0 ps-1"
              data-action="item-selector#remove save-for-later#hideWhenEmpty"
              data-item-selector-id-param="${id}">
        <i class="bi bi-trash"></i>
      </button>
    </div>
  `)

    return li
  }

  update() {
    if (!this.hasItemsTarget) return;

    if (this.itemsTarget.children.length === 0) {
      this.containerTarget.hidden = true
    } else {
      this.containerTarget.hidden = false
    }
  }
}
