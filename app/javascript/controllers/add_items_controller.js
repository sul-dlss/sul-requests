import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['appointmentRequests', 'draftRequests'];

  schedule(e) {
    const appointmentRequests = document.querySelector("#appointmentRequests");
    const transactionNumber = e.currentTarget.dataset.transactionNumber;
    const inAppointments = appointmentRequests.querySelector(`[data-title="${e.currentTarget.dataset.title}"]`)
    if (!inAppointments){
      let element = this.element.cloneNode(true);
      element.querySelectorAll('li').forEach((li) => {
        if (li.dataset.transactionNumber != transactionNumber) {
          li.remove()
        }
        else { 
          this.updateButtonForm(li, transactionNumber);
          this.element.querySelector(`#${li.id}`).remove()
        }
      })
      appointmentRequests.appendChild(element)
    } else {
      const addTo = this.element.querySelector(`li[data-transaction-number="${transactionNumber}"]`);
      this.updateButtonForm(addTo, transactionNumber);
      inAppointments.querySelector('ul').appendChild(addTo)
    }
  }
  updateButtonForm(element, transactionNumber) {
    let input = document.createElement("input");
    input.type = 'hidden'
    input.name = 'update_requests[]'
    input.value = transactionNumber
    element.appendChild(input)
    element.querySelector('button').remove();
  }
}