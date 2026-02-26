import { Controller } from "@hotwired/stimulus"
import { Collapse } from "bootstrap"
import sanitizeHtml from 'sanitize-html';

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
  static targets = ["items", "volumesDisplay", "requestTypeDisplay", "digitizationItems", "digitizationTemplate", "appointmentItems", "appointmentTemplate"]
  static values = { selectedItems: Array, requestType: String }

  updateVolumesDisplay(event) {
    if (!this.hasVolumesDisplayTarget) return;

    // Get all checked volume checkboxes
    const checkedBoxes = this.element.querySelectorAll('input[name="volumes[]"]:checked');
    
    if (checkedBoxes.length === 0) {
      this.volumesDisplayTarget.innerHTML = '<li class="text-muted">No items selected</li>';
    } else {
      const listItems = Array.from(checkedBoxes)
        .map(cb => `<li>${cb.value}</li>`)
        .join('');
      this.volumesDisplayTarget.innerHTML = listItems;
    }
  }

  itemsTargetConnected(element) {
    if (!element.checked) return;

    const params = this.getStimulusParams(element);

    if (!this.selectedItemsValue.find((item) => item.id == params.id)) {
      this.selectedItemsValue = this.selectedItemsValue.concat([params]);
    }
  }

  itemChanged(event) {
    if (event.currentTarget.checked || event.params.checked) {
      this.selectedItemsValue = this.selectedItemsValue.concat([event.params]);
    } else {
      this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);
    }

    this.dispatch('change', { detail: { selectedItems: this.selectedItemsValue }});
  }

  formatItemTitle(item) {
    const segments = [];
    if (item.series) segments.push(sanitizeHtml(item.series));
    if (item.subseries) segments.push(sanitizeHtml(item.subseries));

    return segments.join('<i class="bi bi-chevron-right mx-1"></i>');
  }

  appendDigitizationItem(item) {
    // Create the digitization section
    const template = this.digitizationTemplateTarget;
    const element = document.importNode(template.content, true);
    const rootNode = element.querySelector('div');
    rootNode.dataset.contentId = item.id;
    rootNode.dataset.fieldsBaseName = rootNode.dataset.fieldsBaseName.replace('__DOMID__', item.id);
    rootNode.innerHTML = rootNode.innerHTML.replace(/__TITLE__/g, this.formatItemTitle(item)).replace(/__DOMID__/g, item.id);

    if (this.requestTypeValue != 'scan') this.disableRequiredInputs(rootNode);
    return this.digitizationItemsTarget.appendChild(rootNode);
  }

  appendAppointmentItem(item) {
    const template = this.appointmentTemplateTarget;
    const element = document.importNode(template.content, true);
    const rootNode = element.querySelector('div');
    rootNode.dataset.contentId = item.id;
    rootNode.dataset.fieldsBaseName = rootNode.dataset.fieldsBaseName.replace('__DOMID__', item.id);
    rootNode.innerHTML = rootNode.innerHTML.replace(/__TITLE__/g, this.formatItemTitle(item)).replace(/__DOMID__/g, item.id);
    if (this.requestTypeValue == 'scan') this.disableRequiredInputs(rootNode);

    this.appointmentItemsTarget.appendChild(rootNode);
  }

  selectedItemsValueChanged(value, previousValue) {
    const removed = (previousValue || []).filter(item => !value.find(v => v.id == item.id));
    const added = value.filter(item => !(previousValue || []).find(v => v.id == item.id));

    removed.forEach(item => {
      // remove the digitization section, physical item section, and hidden inputs for the item
      this.element.querySelectorAll(`[data-content-id="${item.id}"]`).forEach(e => e.remove());
    });

    added.forEach(item => {
      const digitizationItem = this.appendDigitizationItem(item);
      this.appendAppointmentItem(item);

      // Create hidden inputs for the rst of the item's data
      const baseName = digitizationItem.dataset.fieldsBaseName;
      const hiddenContainer = document.createElement('div');
      hiddenContainer.classList.add('d-none');
      hiddenContainer.dataset.contentId = item.id;

      Object.entries(item).forEach(([key, value]) => {
        const input = document.createElement('input');
        input.type = 'hidden';
        input.name = `${baseName}[${key}]`;
        input.value = value;

        hiddenContainer.appendChild(input);
      });
      this.element.appendChild(hiddenContainer);
    });

    if (!this.digitizationItemsTarget.querySelector('[data-content-id] .accordion-collapse.show')) {
      const first = this.digitizationItemsTarget.querySelector('[data-content-id] .accordion-collapse');

      if (first) Collapse.getOrCreateInstance(first).show();
    }
  }

  updateRequestType(event) {
    if (!this.hasRequestTypeDisplayTarget) return;

    const label = event.target.labels[0]?.textContent.trim() || event.target.value;
    this.requestTypeDisplayTarget.textContent = label;
    this.requestTypeDisplayTarget.classList.remove('text-muted');

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

  // Temporarily disable required inputs that are children of the given element
  // This is used to prevent validation errors when hidden/unused inputs are required
  // The initial required state of the inputs is preserved via a data attribute
  disableRequiredInputs(element) {
    element.querySelectorAll('[required]').forEach(input => {
      input.dataset.required = true;
      input.removeAttribute('required');
    });
  }

  deleteItem(event) {
    event.preventDefault();
    const deleteId = event.currentTarget.dataset.deleteId;

    // uncheck item from previous accordion
    const target = this.itemsTargets.find((item) => item.dataset.archivesRequestIdParam === deleteId)
    if (target) target.checked = false;

    // remove select items from value list
    this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== deleteId);

    // go back to item selector if all selected items deleted
    if (this.selectedItemsValue.length == 0) {
      this.showItemSelector()
    }
  }

  showItemSelector() {
    const accordionController = this.application.getControllerForElementAndIdentifier(this.element, 'accordion-form');
    accordionController.goto('items-accordion');

    accordionController.reenableNextButtons();
  }


  nextItem(event) {
    event.preventDefault();
    event.stopPropagation();

    const currentItem = event.target.closest('[data-content-id]');
    const nextItem = currentItem.nextElementSibling;

    const currentCollapse = currentItem.querySelector('.accordion-collapse');
    const nextCollapse = nextItem?.querySelector('.accordion-collapse');

    if (currentCollapse && nextCollapse) {
      Collapse.getOrCreateInstance(currentCollapse).hide();
      Collapse.getOrCreateInstance(nextCollapse).show();
    }
  }
}
