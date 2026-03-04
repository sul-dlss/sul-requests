import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  updateType(event) {
    const requestType = event.target.value;

    // this variable is null on the archives request page
    const itemSelector = this.element.querySelector('[data-controller="item-selector"]');
    if (itemSelector) itemSelector.dataset.itemSelectorRequestTypeValue = requestType;

    this.element.dataset.accordionFormTypeValue = requestType;
    // this was set in patron request controller earlier but not archives request controller
    this.element.dataset.itemSelectorItemLimitValue = this.typeValue != 'aeon' && requestType == 'scan' ? 1 : -1;
  }
}
