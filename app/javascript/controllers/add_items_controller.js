import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  schedule(e) {
    e.preventDefault()
    const data = e.currentTarget.dataset;
    setTimeout(() => {
      this.updateElements(data, 'items-added')
    }, 1000);
  }

  updateElements(data, eventName){
    const appointmentRequests = document.querySelector(data.appointmentTarget);
    // if accordion isn't open, open it
    if (!appointmentRequests.classList.contains('show')){
      document.querySelector(`[data-bs-target="${data.appointmentTarget}"]`).click();
    }
    const template = appointmentRequests.querySelector('template')
    const transactionNumber = data.transactionNumber;
    const inAppointments = appointmentRequests.querySelector(`[data-title="${data.title}"]`)
    if (!inAppointments){
      let element = this.element.cloneNode(true);
      element.querySelectorAll('li').forEach((li) => {
        if (li.dataset.transactionNumber != transactionNumber) {
          li.remove()
        }
        else { 
          this.updateButtonForm(li, template, eventName);
          this.addFlashAnimation(li)
          this.element.querySelector(`#${li.id}`).remove()
        }
      })
      appointmentRequests.querySelector('.accordion-body').appendChild(element)
    } else {
      const addTo = this.element.querySelector(`li[data-transaction-number="${transactionNumber}"]`);
      this.updateButtonForm(addTo, template, eventName);
      inAppointments.querySelector('ul').appendChild(addTo);
      this.addFlashAnimation(addTo)
    }
    if (this.element.querySelectorAll('li').length < 1) this.element.remove()
    const addAmount = eventName == 'items-removed' ? -1 : 1
    window.dispatchEvent(new CustomEvent('items-updated', { detail: { addAmount } }))
  }

  remove(e) {
    e.preventDefault()
    const data = e.currentTarget.dataset;
    setTimeout(() => {
      this.updateElements(data, 'items-removed')
    }, 1000);
  }

  enableDisableButton(e) {
    this.element.querySelectorAll('button').forEach(button=> {
      button.disabled = e.detail.percentage > 99
    })
  }

  addFlashAnimation(li) {
    li.classList.add('flash-on-add')
    li.addEventListener('animationend', (e) => {
      if (e.animationName == 'flash') li.classList.remove('flash-on-add');
    });
  }

  updateButtonForm(element, template, eventName) {
    const actionTemplate = document.importNode(template.content, true).querySelector('.actions')
    const newButton = actionTemplate.querySelector('button')
    const oldButton = element.querySelector('button')
    newButton.dataset.title = oldButton.dataset.title
    newButton.dataset.transactionNumber = oldButton.dataset.transactionNumber
    newButton.hidden = false
    element.querySelector('.actions').replaceWith(actionTemplate);
    let input = element.querySelector('input') ? element.querySelector('input') : document.createElement("input");
    input.type = 'hidden'
    input.name = `${eventName.replace('-', '_')}[]`
    input.value = oldButton.dataset.transactionNumber
    element.appendChild(input)
  }
}
