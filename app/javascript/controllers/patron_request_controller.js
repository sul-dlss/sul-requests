import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['earliestAvailable', 'destination', 'proxyScanWarning', 'sponsorScanWarning', 'selectSponsor', 'sponsorRadioButton', 'digitization', 'reading']

  connect() {
    this.element.reset();
  }

  emptyFields(accordion) {
    const formData = new FormData(accordion.closest('form'));
    return Array.from(accordion.querySelectorAll('[required],input[name="patron_request[barcodes][]"]')).find(x => formData.getAll(x.name).every(x => !x))
  }

  showItemSelector(event) {
    const accordionController = this.application.getControllerForElementAndIdentifier(this.element, 'accordion-form');

    if (event.detail.selectedItems.length == 0) {
      accordionController.goto('barcodes-accordion');
    }

    accordionController.reenableNextButtons();
  }

  showHideItemGroups(event) {
    const itemGroups = this.element.querySelectorAll('.selected-items-container');

    Array.from(itemGroups).forEach(itemGroup => {
      if (!itemGroup.querySelector('[data-content-id]')) {
        itemGroup.classList.add('d-none');
        this.disableRequiredInputs(itemGroup);
      } else {
        itemGroup.classList.remove('d-none');
        this.enableRequiredInputs(itemGroup);
      }
    });
  }

  updateType(event) {
    const requestType = event.target.value;

    const itemSelector = this.element.querySelector('[data-controller="itemselector"]');
    if (itemSelector) itemSelector.dataset.itemselectorRequestTypeValue = requestType;

    this.element.dataset.accordionFormTypeValue = requestType;
    this.element.dataset.itemselectorItemLimitValue = requestType == 'scan' ? 1 : -1;
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
        var id = selectedItem.id
        _this.showDigitizationOption(id)
      })
    } else if(requestType == 'reading'){
      event.detail.selectedItems.forEach(selectedItem => { 
        var id = selectedItem.id
        _this.showReadingOption(id)
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

  showDigitizationOption(id) {
    const digitizationTarget = this.digitizationTargets.find(t => t.dataset.id == id)
    this.enableRequiredInputs(digitizationTarget)
    digitizationTarget.querySelectorAll("input, textarea").forEach(element => {
      element.disabled = false
    })

    digitizationTarget.classList.remove('d-none')
  }

  showReadingOption(id) {
    const readingTarget = this.readingTargets.find(t => t.dataset.id == id)
  
    readingTarget.classList.remove('d-none')
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
