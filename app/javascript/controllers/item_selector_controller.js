import { Controller } from "@hotwired/stimulus";
import { Toast } from 'bootstrap';

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
  static targets = ['items', 'toast', 'selectedItems']
  static values = { requestType: String, selectedItems: Array }

  connect() { }

  itemsTargetConnected(element) {
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
      this.itemsTargets.forEach(i => i.closest('tr').classList.remove('d-none'))
    } else {
      this.itemsTargets.forEach(i => {
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
      if (this.itemsTarget.type == 'radio') {
        this.selectedItemsValue = [event.params];
      } else {
        this.selectedItemsValue = this.selectedItemsValue.concat([event.params]);
      }
    } else {
      this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);
    }

    // Enable/disable sending hidden params to Aeon
    event.currentTarget.closest('td').querySelectorAll('[data-toggle]').forEach(e => e.toggleAttribute('disabled'));

    this.dispatch('change', { detail: { selectedItems: this.selectedItemsValue } });
  }

  unchecked(event) {
    event.preventDefault();

    const target = this.itemsTargets.find((item) => item.dataset.itemselectorIdParam === event.params.id)
    if (target) target.checked = false;

    const targetItem = this.selectedItemsValue.find((item) => item.id == event.params.id)

    this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);

    if (this.selectedItemsValue.length > 0) this.showRemovalToast(targetItem);

    this.dispatch('change', { detail: { selectedItems: this.selectedItemsValue } });
  }

  undo(event) {
    event.preventDefault();

    this.itemsTargets.find((item) => item.dataset.itemselectorIdParam === event.params.id).click();
    Toast.getOrCreateInstance(this.toastTarget).hide();
  }

  showRemovalToast(item) {
    this.toastTarget.querySelector('.btn').dataset.itemselectorIdParam = item.id;

    Toast.getOrCreateInstance(this.toastTarget).show();
  }

  requestTypeValueChanged(value) {
    const switchtype = value == 'scan' ? 'radio' : 'checkbox'

    this.itemsTargets.forEach(elem => {
      elem.type = switchtype;
      if (switchtype == 'radio') { elem.checked = false };
    })
  }

  selectedItemsValueChanged(value, previousValue) {
    const removed = (previousValue || []).filter(item => !value.find(v => v.id == item.id));
    const added = value.filter(item => !(previousValue || []).find(v => v.id == item.id));

    removed.forEach(item => {
      // remove the digitization section, physical item section, and hidden inputs for the item
      this.element.querySelectorAll(`[data-content-id="${item.id}"]:not([data-toggle-disabled])`).forEach(e => e.remove());

      this.element.querySelectorAll(`[data-content-id="${item.id}"][data-toggle-disabled]`).forEach(e => this.disableInputs(e));
    });

    added.forEach(item => {
      this.element.querySelectorAll(`[data-content-id="${item.id}"][data-toggle-disabled]`).forEach(e => this.enableInputs(e));

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

          target.appendChild(rootNode);
        }
      })
    });

    this.selectedItemsTargets.forEach(target => {
      const itemGroup = target.closest('.selected-items-container')
      if (!target.querySelector('[data-content-id]')) {
        itemGroup.classList.add('d-none');
        this.disableRequiredInputs(itemGroup);
      } else {
        itemGroup.classList.remove('d-none');
        this.enableRequiredInputs(itemGroup);
      }
    });

    this.dispatch('changed', { detail: { selectedItems: value } });
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

  enableRequiredInputs(element) {
    element.querySelectorAll('[data-required]').forEach(input => {
      input.setAttribute('required', 'required');
    });
  }

  disableInputs(element) {
    element.querySelectorAll('[data-toggle]').forEach(input => {
      input.addAttribute('disabled');
    });
  }

  enableInputs(element) {
    element.querySelectorAll('[data-toggle]').forEach(input => {
      input.removeAttribute('disabled');
    });
  }
}
