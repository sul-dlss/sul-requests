import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['accordion']
  static values = { type: { type: String, default: '' } }

  connect() {
    if (this.accordionTargets.length == 1) {
      this.removeAccordionStyling();
    }
  }

  typeValueChanged() {
    if (this.typeValue == '') return;

    this.accordionTargets.forEach(accord => {
      if (accord.dataset.patronrequestForrequesttype == this.typeValue) {
        accord.classList.remove('d-none');
        this.enableRequiredInputs(accord);
      } else if (accord.dataset.patronrequestForrequesttype) {
        accord.classList.add('d-none');
        this.disableRequiredInputs(accord);
      }
    });
  }

  accordionTargetConnected(element) {
    this.enableNextButton(element);
  }

  emptyFields(accordion) {
    const formData = new FormData(accordion.closest('form'));

    return Array.from(accordion.querySelectorAll('[required],input[name="ead_request[volumes][]"],input[name="patron_request[barcodes][]"]')).find(x => formData.getAll(x.name).every(x => !x))
  }

  enableAnyNextButtons(event) {
    event.target.querySelectorAll('.accordion-item').forEach(accord => this.enableNextButton(accord));
  }

  reenableNextButtons() {
    this.accordionTargets.forEach(accord => this.enableNextButton(accord));
  }

  goto(id) {
    const acc = this.accordionTargets.find(e => e.id == id).querySelector('.accordion-collapse');
    if (!acc.classList.contains('show')) this.show(acc);
  }

  enableNextButton(event) {
    const accord = event.currentTarget ? event.currentTarget.closest('.accordion-item') : event;
    const accordbutton = accord.querySelector('[data-next-step-button]');
    if (!this.emptyFields(accord) && accordbutton) {
      accordbutton.disabled = false;
    } else if (accordbutton) {
      accordbutton.disabled = true;
    }
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

    this.show(previousitem.querySelector('.accordion-collapse'));
  }

  nextStep(event) {
    const accordion = event.target.closest('.accordion-item');

    // Don't allow moving to the next step unless all required fields are completed
    if (this.emptyFields(accordion)) {
      event.preventDefault();
      return;
    }

    // mark the current step as completed
    const accordionbutton = accordion.querySelector('.accordion-header');
    accordionbutton.parentElement.classList.add('completed');

    var nextitem = this.findNextAccordion(accordion);
    if (!nextitem) return;

    this.show(nextitem.querySelector('.accordion-collapse'));
    event.preventDefault();
  }

  findNextAccordion(accordion) {
    // figure out what the next step is:
    const accordions = this.accordionTargets.filter(e => !e.classList.contains('step-placeholder') && !e.classList.contains('d-none'));
    const current = accordions.findIndex( x => x == accordion);
    return accordions.at(current+1);
  }

  // show the next step in the request form. Bootstrap will toggle the other steps closed,
  // and we have to do some bookkeeping with the placeholder elements to hide them (if the non-placeholder step is visible)
  // or show them (if we've stepped back)
  show(accordionCollapseElement) {
    const accordionitem = accordionCollapseElement.closest('.accordion-item');
    accordionitem.classList.remove('d-none');

    Collapse.getOrCreateInstance(accordionCollapseElement).show();

    this.accordionTargets.slice(this.accordionTargets.indexOf(accordionitem)).forEach(el => {
      el.classList.remove('completed');
      const nextbutton = el.querySelector('[data-next-step-button]');
      if (nextbutton) { nextbutton.disabled = true; }
    });
    this.enableNextButton(accordionCollapseElement);

    this.dispatch('show', { detail: { step: accordionitem } });
  }

  editStep(event) {
    event.target.parentElement.classList.remove('completed');
    this.show(event.target.closest('.accordion-item').querySelector('.accordion-collapse'));

    event.preventDefault();
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
}
