import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['earliestAvailable', 'accordion']

  connect() {
    if (this.accordionTargets.length == 1) {
      this.removeAccordionStyling();
    }
  }

  removeAccordionStyling() {
    this.element.classList.remove('accordion');

    const accordion = this.accordionTargets[0];
    accordion.classList.remove('d-none');
    accordion.classList.remove('shadow-sm');
    accordion.querySelector('.accordion-header').remove();
  }

  nextStep(event) {
    const accordion = event.target.closest('.accordion-item');

    // mark the current step as completed
    const accordionbutton = accordion.querySelector('.accordion-header');
    accordionbutton.parentElement.classList.add('completed');

    // figure out what the next step is:
    const accordions = this.accordionTargets.filter(e => !e.classList.contains('step-placeholder'));
    const current = accordions.findIndex( x => x == accordion);
    var nextitem = accordions.at(current+1).id.split('-accordion')[0];

    // ... but the pickup or scan step varies based on data in the form:
    const formdata = new FormData(this.element);
    nextitem = (nextitem == 'pickup' || nextitem == 'scan') && formdata.get('patron_request[request_type]') ? formdata.get('patron_request[request_type]') : nextitem;
    var nextstep = document.querySelector(`#${nextitem}`);

    this.showStep(nextstep);
    event.preventDefault();
  }

  editForm(event) {
    event.target.parentElement.classList.remove('completed');
    this.showStep(event.target.closest('.accordion-item').querySelector('.accordion-collapse'));

    event.preventDefault();
  }

  // show the next step in the request form. Bootstrap will toggle the other steps closed,
  // and we have to do some bookkeeping with the placeholder elements to hide them (if the non-placeholder step is visible)
  // or show them (if we've stepped back)
  showStep(accordionCollapseElement) {
    const accordionitem = accordionCollapseElement.closest('.accordion-item');
    accordionitem.classList.remove('d-none');

    Collapse.getOrCreateInstance(accordionCollapseElement).show();

    if (accordionitem.dataset.patronrequestPlaceholder) {
      this.element.querySelector(accordionitem.dataset.patronrequestPlaceholder).classList.add('d-none');
      this.element.querySelectorAll(`[data-patronRequest-placeholder="${accordionitem.dataset.patronrequestPlaceholder}"]`).forEach(el => { el != accordionitem && el.classList.add('d-none') });
    }

    this.accordionTargets.slice(this.accordionTargets.indexOf(accordionitem) + 1).forEach(el => {
      if (el.dataset.patronrequestPlaceholder && !el.classList.contains('d-none')) {
        el.classList.add('d-none');
        this.element.querySelector(el.dataset.patronrequestPlaceholder).classList.remove('d-none');
      }

      el.classList.remove('completed');
    });
  }

  async updateEarliestAvailable(event) {
    const url = new URL(this.earliestAvailableTarget.src + "/../" + event.currentTarget.value);

    this.earliestAvailableTarget.src = url;
  }
}
