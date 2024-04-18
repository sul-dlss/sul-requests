import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['earliestAvailable', 'accordion']

  connect() {
    if (this.accordionTargets.length == 1) {
      this.removeAccordionStyling();
    }
  }

  updateType(event) {
    const requestType = event.target.value;

    this.accordionTargets.filter(e => e.dataset.patronrequestForrequesttype).forEach(el => {
      if (el.dataset.patronrequestForrequesttype == requestType) {
        el.classList.remove('d-none');
      } else {
        el.classList.add('d-none');
      }
    });
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
    const accordions = this.accordionTargets.filter(e => !e.classList.contains('step-placeholder') && !e.classList.contains('d-none'));
    const current = accordions.findIndex( x => x == accordion);
    var nextitem = accordions.at(current+1);

    this.showStep(nextitem.querySelector('.accordion-collapse'));
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

    this.accordionTargets.slice(this.accordionTargets.indexOf(accordionitem)).forEach(el => {
      el.classList.remove('completed');
    });
  }

  async updateEarliestAvailable(event) {
    const url = new URL(this.earliestAvailableTarget.src + "/../" + event.currentTarget.value);

    this.earliestAvailableTarget.src = url;
  }
}
