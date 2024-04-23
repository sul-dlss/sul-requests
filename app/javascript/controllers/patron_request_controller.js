import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['earliestAvailable', 'accordion', 'destination']

  connect() {
    if (this.accordionTargets.length == 1) {
      this.removeAccordionStyling();
    }
  }

  showItemSelector(event) {
    if (event.detail.selectedItems.length == 0) {
      const acc = this.accordionTargets.find(e => e.id == 'barcodes-accordion').querySelector('.accordion-collapse');
      if (!acc.classList.contains('show')) this.showStep(acc);
    }
  }

  updateType(event) {
    const requestType = event.target.value;

    var nextitem = this.findNextAccordion(event.target.closest('.accordion-item'));
    if (nextitem && nextitem.dataset.switchSelector) {
      const searchtype = requestType == 'scan' ? 'checkbox' : 'radio'
      const switchtype = requestType == 'scan' ? 'radio' : 'checkbox'
      const items = nextitem.querySelectorAll(`input[type="${searchtype}"]`);
      items.forEach(elem => {
        elem.type = switchtype;
      })
    }


    this.accordionTargets.filter(e => e.dataset.patronrequestForrequesttype).forEach(el => {
      if (el.dataset.patronrequestForrequesttype == requestType) {
        el.classList.remove('d-none');
        this.enableRequiredInputs(el);
      } else {
        el.classList.add('d-none');
        this.disableRequiredInputs(el);
      }
    });
  }

  // Temporarily disable required inputs that are children of the given element
  // This is used to prevent validation errors when hidden/unused inputs are required
  // The initial required state of the inputs is preserved via a data attribute
  disableRequiredInputs(element) {
    element.querySelectorAll('[required]').forEach(input => {
      input.dataset.required = true;
      input.removeAttribute('required');
    });
  }

  enableRequiredInputs(element) {
    element.querySelectorAll('[data-required]').forEach(input => {
      input.setAttribute('required', 'required');
    });
  }

  removeAccordionStyling() {
    this.element.classList.remove('accordion');

    const accordion = this.accordionTargets[0];
    accordion.classList.remove('d-none');
    accordion.classList.remove('shadow-sm');
    accordion.querySelector('.accordion-header').remove();
  }

  previousStep(event) {
    const accordion = event.target.closest('.accordion-item');

    // figure out what the last step is:
    const accordions = this.accordionTargets.filter(e => !e.classList.contains('step-placeholder') && !e.classList.contains('d-none'));
    const current = accordions.findIndex( x => x == accordion);
    var previousitem = accordions.at(current-1) || accordions[0];

    this.showStep(previousitem.querySelector('.accordion-collapse'));
  }

  nextStep(event) {
    const accordion = event.target.closest('.accordion-item');
    const formData = new FormData(accordion.closest('form'));

// Don't allow moving to the next step unless all required fields are completed
    if (Array.from(accordion.querySelectorAll('[required], [data-required]')).find(x => formData.getAll(x.name).every(x => !x))) {
      event.preventDefault();
      return;
    }

    // mark the current step as completed
    const accordionbutton = accordion.querySelector('.accordion-header');
    accordionbutton.parentElement.classList.add('completed');

    var nextitem = this.findNextAccordion(accordion);

    this.showStep(nextitem.querySelector('.accordion-collapse'));
    event.preventDefault();
  }

  findNextAccordion(accordion) {
    // figure out what the next step is:
    const accordions = this.accordionTargets.filter(e => !e.classList.contains('step-placeholder') && !e.classList.contains('d-none'));
    const current = accordions.findIndex( x => x == accordion);
    return accordions.at(current+1);
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
    const destinationName = event.target.selectedOptions[0].textContent;
    this.earliestAvailableTarget.src = url;
    this.destinationTarget.textContent = destinationName;
  }
}
