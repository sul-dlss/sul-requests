import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  schedule(e) {
    this.updateElements(e, 'items-added')
  }

  updateElements(e, eventName){
    const appointmentRequests = document.querySelector(e.currentTarget.dataset.appointmentTarget);
    const template = appointmentRequests.querySelector('template')
    const transactionNumber = e.currentTarget.dataset.transactionNumber;
    const inAppointments = appointmentRequests.querySelector(`[data-title="${e.currentTarget.dataset.title}"]`)
    if (!inAppointments){
      let element = this.element.cloneNode(true);
      element.querySelectorAll('li').forEach((li) => {
        if (li.dataset.transactionNumber != transactionNumber) {
          li.remove()
        }
        else { 
          this.updateButtonForm(li, template, eventName);
          this.element.querySelector(`#${li.id}`).remove()
        }
      })
      appointmentRequests.querySelector('.accordion-body').appendChild(element)
    } else {
      const addTo = this.element.querySelector(`li[data-transaction-number="${transactionNumber}"]`);
      this.updateButtonForm(addTo, template, eventName);
      inAppointments.querySelector('ul').appendChild(addTo)
    }
    if (this.element.querySelectorAll('li').length < 1) this.element.remove()
    const addAmount = eventName == 'items-removed' ? -1 : 1
    window.dispatchEvent(new CustomEvent('items-updated', { detail: { addAmount } }))
  }

  remove(e) {
    this.updateElements(e, 'items-removed')
  }

  enableDisableButton(e) {
    this.element.querySelectorAll('button').forEach(button=> {
      button.disabled = e.detail.percentage > 99
    })
  }

  updateButtonForm(element, template, eventName) {
    const cloneTemplate = document.importNode(template.content, true)
    const newButton = cloneTemplate.querySelector('button')
    const oldButton = element.querySelector('button')
    newButton.dataset.title = oldButton.dataset.title
    newButton.dataset.transactionNumber = oldButton.dataset.transactionNumber
    oldButton.replaceWith(newButton);
    let input = element.querySelector('input') ? element.querySelector('input') : document.createElement("input");
    input.type = 'hidden'
    input.name = `${eventName.replace('-', '_')}[]`
    input.value = oldButton.dataset.transactionNumber
    element.appendChild(input)
  }
}
