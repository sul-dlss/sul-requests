import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['earliestAvailable']

  connect() {
    const form = document.getElementById('new_patron_request');
    const accordianbuttons = form.querySelectorAll('.accordion-button');

    accordianbuttons.forEach((accordianbutton, index) => {
      accordianbutton.getElementsByClassName('step-number')[0].innerHTML = index + 1;
      if (index == 0) {
        accordianbutton.removeAttribute('disabled');
        accordianbutton.click();
      }
    });
  }

  nextStep(event) {
    const step = 'patron_request[' + event.target.id + ']';
    const formdata = new FormData(event.target.closest("form"));

    const accordianbutton = document.querySelector(`[data-bs-target='#${event.target.id}']`);
    accordianbutton.parentElement.classList.add('completed');
    accordianbutton.click();
    accordianbutton.setAttribute('disabled', '');

    const nextstepid = formdata.get(step.replace('-', '_'));
    const nextstep = document.querySelector(`[data-bs-target='#${nextstepid}']`);
    this.clickNext(nextstep);
    event.preventDefault();
  }

  editForm(event) {
    event.target.parentElement.classList.remove('completed');
    document.querySelectorAll('.accordion-item').forEach(accordian => {
      accordian.querySelector('.accordion-button').setAttribute('disabled', '');
    })
    document.querySelector('.show').classList.remove('show');
    this.clickNext(event.target.parentElement.querySelector('.accordion-button'));
    event.preventDefault();
  }

  clickNext(element) {
    element.removeAttribute('disabled');
    element.click();
  }

  async updateEarliestAvailable(event) {
    const url = new URL(this.earliestAvailableTarget.src + "/../" + event.currentTarget.value);

    this.earliestAvailableTarget.src = url;
  }
}
