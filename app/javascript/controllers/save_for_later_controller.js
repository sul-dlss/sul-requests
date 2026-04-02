import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['list', 'savedItemTemplate', 'section']

  save(event) {
    event.preventDefault()

    const formItem = event.target.closest('[data-content-id]')
    if (!formItem) return

    const id = formItem.dataset.contentId
    const originSection = this.sectionTargets.find(section => section.contains(formItem))
    if (originSection) this.clearRequiredInputs(originSection, id)

    this.formItemsFor(id).forEach(item => {
      item.classList.add('d-none')
      item.setAttribute('data-saved-for-later', '')
    })

    this.listTargets.forEach(list => list.appendChild(this.makeSavedItem(formItem)))

    // Auto-expand the next visible sibling if this section uses expand/collapse
    let nextItem = formItem.nextElementSibling
    while (nextItem && !nextItem.offsetParent) nextItem = nextItem.nextElementSibling
    const nextCollapse = nextItem?.querySelector('.accordion-collapse')
    if (nextCollapse) Collapse.getOrCreateInstance(nextCollapse).show()

    this.dispatch('changed')
  }

  restore(event) {
    event.preventDefault()

    const savedClone = event.target.closest('[data-content-id]')
    if (!savedClone) return

    const id = savedClone.dataset.contentId

    this.formItemsFor(id).forEach(item => {
      item.classList.remove('d-none')
      item.removeAttribute('data-saved-for-later')
      // Re-run selected-item-form validation now that the item is visible again.
      item.querySelectorAll('[data-required-for-submit]').forEach(input => {
        input.dispatchEvent(new Event('input', { bubbles: true }))
      })
    })

    this.listTargets.forEach(list => {
      list.querySelectorAll(`[data-content-id="${id}"]`).forEach(el => el.remove())
    })

    this.dispatch('changed')
  }

  clearRequiredInputs(section, id) {
    section.querySelectorAll(`[data-content-id="${id}"] [data-required-for-submit]`).forEach(input => {
      input.value = ''
      input.dispatchEvent(new Event('input', { bubbles: true }))
    })
  }

  formItemsFor(id) {
    return Array.from(this.element.querySelectorAll(`[data-content-id="${id}"]:not([data-toggle-disabled])`))
      .filter(el => !this.listTargets.some(list => list.contains(el)))
  }

  makeSavedItem(formItem) {
    const id = formItem.dataset.contentId
    const title = formItem.querySelector('.selected-item-title')
    const clone = this.savedItemTemplateTarget.content.cloneNode(true)
    const li = clone.querySelector('li')

    li.dataset.contentId = id
    li.querySelector('[data-role="title"]').innerHTML = title.innerHTML
    li.querySelector('button').dataset.itemSelectorIdParam = id

    return li
  }
}
