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
  static targets = ["digitizationItems"]

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

  showItemSelector() {
    const accordionController = this.application.getControllerForElementAndIdentifier(this.element, 'accordion-form');
    accordionController.goto('items-accordion');

    accordionController.reenableNextButtons();
  }
}
