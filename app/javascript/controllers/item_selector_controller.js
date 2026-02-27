import { Controller } from "@hotwired/stimulus";
import { Toast } from 'bootstrap';
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
  static targets = ['item', 'toast', 'selectedItems']
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

    this.toastTarget.querySelector('.btn').dataset.itemselectorPayloadParam = JSON.stringify(item);

    Toast.getOrCreateInstance(this.toastTarget).show();
  }

  formatItemTitle(item) {
    if (!item.titleParts) return item.label;

    return item.titleParts.map(e => sanitizeHtml(e)).join('<i class="bi bi-chevron-right mx-1"></i>');
  }

  selectedItemsValueChanged(value, previousValue) {
    const removed = (previousValue || []).filter(item => !value.find(v => v.id == item.id));
    const added = value.filter(item => !(previousValue || []).find(v => v.id == item.id));

    removed.forEach(item => {
      // remove the digitization section, physical item section, and hidden inputs for the item
      this.element.querySelectorAll(`[data-content-id="${item.id}"]:not([data-toggle-disabled])`).forEach(e => e.remove());

      this.element.querySelectorAll(`[data-content-id="${item.id}"][data-toggle-disabled]`).forEach(e => this.disableInputs(e));

      const target = this.itemTargets.find((checkbox) => checkbox.dataset.itemselectorIdParam === item.id)
      if (target) target.checked = false;
    });

    added.forEach(item => {
      this.element.querySelectorAll(`[data-content-id="${item.id}"][data-toggle-disabled]`).forEach(e => this.enableInputs(e));

      const target = this.itemTargets.find((checkbox) => checkbox.dataset.itemselectorIdParam === item.id)
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

    this.dispatch('changed', { detail: { selectedItems: value, previousValue: previousValue } });
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
