import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['list', 'savedItemTemplate', 'section']

  save(event) {
    event.preventDefault()

    const formItem = event.target.closest('[data-content-id]')
    if (!formItem) return

    const id = formItem.dataset.contentId

    // Auto-expand the next visible sibling if this section uses expand/collapse
    let nextItem = formItem.nextElementSibling
    while (nextItem && !nextItem.offsetParent) nextItem = nextItem.nextElementSibling

    // move all the form items (acorss all the different sections) into the saved-for-later state
    this.formItemsFor(id).forEach(item => {
      const section = item.closest('[data-save-for-later-target="section"]')
      const savedForLaterList = section.querySelector('[data-save-for-later-target="list"]')
      const savedItem = this.makeSavedItem(item)
      const appt = item.querySelector('input[name$="[appointment_id]"]')
      if (appt) {
        appt.value = ''
        appt.dispatchEvent(new Event('input', { bubbles: true }))
      }
      const template = document.createElement('template')
      template.content.replaceChildren(item);
      savedItem.appendChild(template);
      savedForLaterList.appendChild(savedItem)
    })


    const nextCollapse = nextItem?.querySelector('.accordion-collapse')
    if (nextCollapse) Collapse.getOrCreateInstance(nextCollapse).show()

    this.dispatch('changed')
  }

  restore(event) {
    event.preventDefault()

    const savedClone = event.target.closest('[data-content-id]')
    if (!savedClone) return

    const id = savedClone.dataset.contentId

    this.sectionTargets.forEach(section => {
      const savedForLaterList = section.querySelector('[data-save-for-later-target="list"]')
      const savedItem = savedForLaterList.querySelector(`[data-content-id="${id}"]`);
      const template = savedItem.querySelector('template')
      const rehydratedItem = document.importNode(template.content, true)
      const selectedItemList = section.querySelector('[data-item-selector-target="selectedItems"]')
      selectedItemList.appendChild(rehydratedItem)
      savedItem.remove();
    });

    this.dispatch('changed')
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
    li.innerHTML = li.innerHTML.replaceAll('__ID__', id)
    li.innerHTML = li.innerHTML.replaceAll('__TITLE__', title.textContent)

    return li
  }
}
