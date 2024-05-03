import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['earliestAvailable', 'accordion', 'destination', 'proxyScanWarning']

  connect() {
    if (this.accordionTargets.length == 1) {
      this.removeAccordionStyling();
    }
    this.accordionTargets.forEach(accord => {
      this.enableNextButton(accord);
    })
    this.element.reset();
  }

  emptyFields(accordion) {
    const formData = new FormData(accordion.closest('form'));
    return Array.from(accordion.querySelectorAll('[required],input[name="patron_request[barcodes][]"]')).find(x => formData.getAll(x.name).every(x => !x))
  }

  enableNextButton(event) {
    const accord = event.target ? event.target.closest('.accordion-item') : event;
    const accordbutton = accord.querySelector('[data-next-step-button]');
    if (!this.emptyFields(accord) && accordbutton) {
      accordbutton.disabled = false;
    } else if (accordbutton) {
      accordbutton.disabled = true;
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

    const itemSelector = this.element.querySelector('[data-controller="itemselector"]');
    if (itemSelector) itemSelector.dataset.itemselectorRequestTypeValue = requestType;

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

  updateProxy(event) {
    if (!this.hasProxyScanWarningTarget) return;

    if (event.target.value == 'share') {
      this.proxyScanWarningTarget.classList.remove('d-none')
    } else {
      this.proxyScanWarningTarget.classList.add('d-none')
    }
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
      const nextbutton = el.querySelector('[data-next-step-button]');
      if (nextbutton) { nextbutton.disabled = true; }
    });
    this.enableNextButton(accordionCollapseElement);
  }

  async updateEarliestAvailable(event) {
    if (!this.hasEarliestAvailableTarget) return;

    const url = new URL(this.earliestAvailableTarget.src + "/../" + event.currentTarget.value);
    const destinationName = event.target.selectedOptions[0].textContent;
    this.earliestAvailableTarget.src = url;
    this.destinationTarget.textContent = destinationName;
  }
}
