import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"

function camelize(value) {
  return value.replace(/(?:[_-])([a-z0-9])/g, (_, char) => char.toUpperCase())
}

function typecast(value) {
  try {
    return JSON.parse(value)
  } catch (o_O) {
    return value
  }
}

export default class extends Controller {
  static targets = ["items", "requestTypeDisplay", "digitizationItems"]
  static values = { selectedItems: Array, requestType: String }

  onSelectedItemsValueChanged(event) {
    if (!this.digitizationItemsTarget.querySelector('[data-content-id] .accordion-collapse.show')) {
      const first = this.digitizationItemsTarget.querySelector('[data-content-id] .accordion-collapse');

      if (first) Collapse.getOrCreateInstance(first).show();
    }

    // go back to item selector if all selected items deleted
    if (event.detail.selectedItems.length == 0 && (event.detail.previousValue || []).length > 0) {
      this.showItemSelector()
    }
  }

  updateRequestType(event) {

    const label = event.target.labels[0]?.textContent.trim() || event.target.value;
    this.requestTypeValue = event.target.value;
    this.element.dataset.accordionFormTypeValue = event.target.value;
  }

  getStimulusParams(element) {
    const params = {}
    const pattern = new RegExp(`^data-${this.identifier}-(.+)-param$`, "i")

    for (const { name, value } of Array.from(element.attributes)) {
      const match = name.match(pattern)
      const key = match && match[1]
      if (key) {
        params[camelize(key)] = typecast(value)
      }
    }

    return params;
  }

  showItemSelector() {
    const accordionController = this.application.getControllerForElementAndIdentifier(this.element, 'accordion-form');
    accordionController.goto('items-accordion');

    accordionController.reenableNextButtons();
  }
}
