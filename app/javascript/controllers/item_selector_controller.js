import { Controller } from "@hotwired/stimulus";
import { Toast } from 'bootstrap';
import DOMPurify from "dompurify";

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
  static targets = ['item', 'toast', 'selectedItems', 'manualInputContainer']
  static values = { itemLimit: { type: Number, default: -1 }, requestType: String, selectedItems: Array }

  connect() { }

  itemLimitValueChanged() {
    const switchtype = this.itemLimitValue == 1 ? 'radio' : 'checkbox';

    this.itemTargets.forEach(elem => {
      elem.type = switchtype;
      if (switchtype == 'radio') { elem.checked = false };
    })
  }

  itemTargetConnected(element) {
    if (!element.checked) return;

    const params = this.getStimulusParams(element);

    if (element.type == 'radio') {
      this.selectedItemsValue = [params];
    } else if (!this.selectedItemsValue.find((item) => item.id == params.id)) {
      this.selectedItemsValue = this.selectedItemsValue.concat([params]);
    }
  }

  filter(event) {
    const filterText = event.currentTarget.value;

    if (filterText.length == 0) {
      this.itemTargets.forEach(i => i.closest('tr').classList.remove('d-none'))
    } else {
      this.itemTargets.forEach(i => {
        if (!i.closest('td').innerText.toLowerCase().includes(filterText.toLowerCase())) {
          i.closest('tr').classList.add('d-none')
        } else {
          i.closest('tr').classList.remove('d-none')
        }
      })
    }
  }

  change(event) {
    if (event.currentTarget.checked || event.params.checked) {
      if (this.itemLimitValue == 1) {
        this.selectedItemsValue = [event.params];
      } else {
        this.selectedItemsValue = this.selectedItemsValue.concat([event.params]);
      }
    } else {
      this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);
    }
  }

  input(event) {
    if (event.currentTarget.value) {
      const value = event.currentTarget.value;
      const index = parseInt(event.currentTarget.dataset.index);
      // This id needs to take the user input because selectedItemsValueChanged won't update the form if the id is the same
      const id = `${event.currentTarget.dataset.prepend}-${value.trim().replace(/[^a-zA-Z0-9]/g, '').replaceAll(' ', '-').toLowerCase()}`;
      const prevId = event.currentTarget.dataset.id;

      // We need to mutate the form so that when we submit the form the elements end up in the same hash
      // so manual-input-1 becomes manual-input-1-box-1
      document.querySelectorAll(`[data-id="${prevId}"`).forEach(elem => {
        elem.name = elem.name.replace(prevId, id);
        elem.dataset.id = id;
      })

      this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.index !== index);
      this.selectedItemsValue = this.selectedItemsValue.concat([{titleParts: [value],
                                                                 id: id,
                                                                 index: index}]);
    }
  }

  addInputField(event) {
    event.preventDefault();
    let template = document.querySelector(event.currentTarget.dataset.template);
    if (template) {
      const inputElements =  document.querySelectorAll('[data-index]');
      const index = parseInt(inputElements[inputElements.length - 1].dataset.index);
      const element = document.importNode(template.content, true);
      const rootNode = element.querySelector('[data-root-node]');
      rootNode.innerHTML = rootNode.innerHTML.replaceAll('__INDEX__', index + 1);
      this.manualInputContainerTarget.appendChild(rootNode);
    }
  }

  removeInputField(event) {
    event.preventDefault()
    event.currentTarget.parentElement.remove();
    const index = parseInt(event.currentTarget.dataset.index);
    this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.index !== index);

    // This has to be done here because after removal of the element the check doesn't run if attatched to the element.
    const accordionController = this.application.getControllerForElementAndIdentifier(this.element, 'accordion-form');
    accordionController.reenableNextButtons();
  }

  remove(event) {
    event.preventDefault();

    const targetItem = this.selectedItemsValue.find((item) => item.id == event.params.id)
    this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);

    if (this.selectedItemsValue.length > 0) this.showRemovalToast(targetItem);
  }

  undo(event) {
    event.preventDefault();

    this.selectedItemsValue = this.selectedItemsValue.concat([event.params.payload]);
    Toast.getOrCreateInstance(this.toastTarget).hide();
  }

  showRemovalToast(item) {
    if (!this.hasToastTarget) return;

    this.toastTarget.querySelector('.btn').dataset.itemSelectorPayloadParam = JSON.stringify(item);

    Toast.getOrCreateInstance(this.toastTarget).show();
  }

  formatItemTitle(item) {
    if (!item.titleParts) return item.label;

    return item.titleParts
      .filter(e => e?.trim())
      .map(e => DOMPurify.sanitize(e))
      .join('<i class="bi bi-chevron-right mx-1"></i>');
  }

  selectedItemsValueChanged(value, previousValue) {
    const removed = (previousValue || []).filter(item => !value.find(v => v.id == item.id));
    const added = value.filter(item => !(previousValue || []).find(v => v.id == item.id));

    removed.forEach(item => {
      // remove the digitization section, physical item section, and hidden inputs for the item
      this.element.querySelectorAll(`[data-content-id="${item.id}"]:not([data-toggle-disabled])`).forEach(e => e.remove());

      this.element.querySelectorAll(`[data-content-id="${item.id}"][data-toggle-disabled]`).forEach(e => this.disableInputs(e));

      const target = this.itemTargets.find((checkbox) => checkbox.dataset.itemSelectorIdParam === item.id)
      if (target) target.checked = false;
    });

    added.forEach(item => {
      this.element.querySelectorAll(`[data-content-id="${item.id}"][data-toggle-disabled]`).forEach(e => this.enableInputs(e));

      const target = this.itemTargets.find((checkbox) => checkbox.dataset.itemSelectorIdParam === item.id)
      if (target) target.checked = true;

      this.selectedItemsTargets.forEach(target => {
        if (target.dataset.statusFilter && target.dataset.statusFilter !== item.status) return;

        let template = document.querySelector(target.dataset.template);
        if (template) {
          const element = document.importNode(template.content, true);
          const rootNode = element.querySelector('[data-content-id]');
          rootNode.dataset.contentId = item.id;

          for (const [key, value] of Object.entries(item)) {
            rootNode.innerHTML = rootNode.innerHTML.replace(new RegExp(`__${key.toUpperCase()}__`, 'g'), value);
          };
          rootNode.innerHTML = rootNode.innerHTML.replace(new RegExp(`__TITLE__`, 'g'), this.formatItemTitle(item));

          target.appendChild(rootNode);
        }
      })
    });

    this.updateAccordionButtonState();
    this.dispatch('changed', { detail: { selectedItems: value, previousValue: previousValue } });
  }

  updateAccordionButtonState() {
    this.selectedItemsTargets.forEach(target => {
      const buttons = [...target.querySelectorAll('.accordion-button')];
      const disable = buttons.length === 1;
      buttons.forEach(button => button.toggleAttribute('disabled', disable));
    });
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

  disableInputs(element) {
    element.querySelectorAll('[data-toggle]').forEach(input => {
      input.setAttribute('disabled', '');
    });
  }

  enableInputs(element) {
    element.querySelectorAll('[data-toggle]').forEach(input => {
      input.removeAttribute('disabled');
    });
  }
}
