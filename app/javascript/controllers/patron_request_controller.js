import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

export default class extends Controller {
  static targets = ['earliestAvailable', 'accordion', 'destination', 'proxyScanWarning', 'sponsorScanWarning', 'selectSponsor', 'sponsorRadioButton', 'digitization', 'reading']

  connect() {
    if (this.accordionTargets.length == 1) {
      this.removeAccordionStyling();
    }

    this.element.reset();
  }

  accordionTargetConnected(element) {
    this.enableNextButton(element);
  }

  emptyFields(accordion) {
    const formData = new FormData(accordion.closest('form'));
    return Array.from(accordion.querySelectorAll('[required],input[name="patron_request[barcodes][]"]')).find(x => formData.getAll(x.name).every(x => !x))
  }

  enableAnyNextButtons(event) {
    event.target.querySelectorAll('.accordion-item').forEach(accord => this.enableNextButton(accord));
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

  showItemSelector(event) {
    if (event.detail.selectedItems.length == 0) {
      const acc = this.accordionTargets.find(e => e.id == 'barcodes-accordion').querySelector('.accordion-collapse');
      if (!acc.classList.contains('show')) this.showStep(acc);
    }

    this.accordionTargets.forEach(accord => {
      this.enableNextButton(accord);
    })
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

  // When the user selects that the request is for a sponsor, make scan warning visible in scan section
  updateForSponsor(event) {
    if (!this.hasSponsorScanWarningTarget) return;

    if (event.target.value == 'share') {
      this.sponsorScanWarningTarget.classList.remove('d-none')
    } else {
      this.sponsorScanWarningTarget.classList.add('d-none')
    }

  }

  // When the user says the request is for a sponsor, display the sponsor selection list
  // Also require a sponsor selection only if the user selects that the request is for a sponsor. 
  toggleDisplaySponsorList(event) {
    if(event.target.value == 'share') {
      this.selectSponsorTarget.classList.remove('d-none')
      this.sponsorRadioButtonTargets.forEach(sponsorRadioButton => { sponsorRadioButton.required = true })
    } else {
      this.selectSponsorTarget.classList.add('d-none')
      this.sponsorRadioButtonTargets.forEach(sponsorRadioButton => {
        sponsorRadioButton.required = false
        sponsorRadioButton.checked = false
      })
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
    if (this.hasEarliestAvailableTarget) {
      const url = new URL(this.earliestAvailableTarget.src.replace(/\/to\/[^/\?]+/, '/to/' + event.currentTarget.value));
      this.earliestAvailableTarget.src = url;
    }

    if (this.hasDestinationTarget) {
      const destinationName = event.target.selectedOptions[0].textContent;
      this.destinationTarget.textContent = destinationName;
    }
  }

  // When items are selected or deselected, update the Aeon reading and digitization options
  // accordingly, if digitization is the request type that is currently selected
  updateAeonOptions(event) {
    const selectedItems = event.detail.selectedItems

    const requestType = this.element.querySelector('input[name="patron_request[request_type]"]:checked').value
    const _this = this


    // Hide and disable all digitization options
    this.hideAllDigitizationOptions()
    if(requestType == 'digitization') {
      event.detail.selectedItems.forEach(selectedItem => { 
        var callnumber = selectedItem.label 
        _this.showDigitizationOption(callnumber)
      })
    } else if(requestType == 'reading'){
      event.detail.selectedItems.forEach(selectedItem => { 
        var callnumber = selectedItem.label 
        _this.showReadingOption(callnumber)
      })
    }
  }

  hideAllDigitizationOptions() {
    var _this = this
    this.digitizationTargets.forEach(digitizationTarget => {
      // Also disable required inputs so that the next/continue button will work
      // when the visible/enabled sections' required inputs have been filled out
      _this.disableRequiredInputs(digitizationTarget)
      digitizationTarget.querySelectorAll("input, textarea").forEach(element => {
        element.disabled = true
      })
      digitizationTarget.classList.add('d-none')
    })
  }

  showDigitizationOption(callnumber) {
    const digitizationTarget = this.digitizationTargets.find(t => t.dataset.callnumber == callnumber)
    this.enableRequiredInputs(digitizationTarget)
    digitizationTarget.querySelectorAll("input, textarea").forEach(element => {
      element.disabled = false
    })

    digitizationTarget.classList.remove('d-none')
  }

  showReadingOption(callnumber) {
    const readingTarget = this.readingTargets.find(t => t.dataset.callnumber == callnumber)
  
    readingTarget.classList.remove('d-none')
  }
}
