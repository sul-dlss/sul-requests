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
  static targets = ['items', 'toast', 'availableItems', 'unavailableItems', 'scanItem', 'unavailableScanItemEstimate', 'availableScanItemEstimate']
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
        if(!i.closest('td').innerText.toLowerCase().includes(filterText.toLowerCase())) {
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

    this.dispatch('change', { detail: { selectedItems: this.selectedItemsValue }});
  }

  unchecked(event) {
    event.preventDefault();

    const target = this.itemsTargets.find((item) => item.dataset.itemselectorIdParam === event.params.id)
    if (target) target.checked = false;

    const targetItem = this.selectedItemsValue.find((item) => item.id == event.params.id)

    this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);

    if (this.selectedItemsValue.length > 0) this.showRemovalToast(targetItem);

    this.dispatch('change', { detail: { selectedItems: this.selectedItemsValue }});
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

  selectedItemsValueChanged() {
    let availableItems = [];
    let unavailableItems = [];

    this.selectedItemsValue.forEach((item) => {
      if (item.available === true) {
        availableItems.push(item);
      } else {
        unavailableItems.push(item);
      }
    });

    this.availableItemsTarget.innerHTML = this.renderItems(availableItems);
    this.unavailableItemsTarget.innerHTML = this.renderItems(unavailableItems);

    if (availableItems.length && this.targets.find('scanItem')) {
      this.scanItemTarget.innerHTML = this.renderItems(availableItems, true);
      this.unavailableScanItemEstimateTarget.classList.add('d-none');
      this.availableScanItemEstimateTarget.classList.remove('d-none');
    } else if (unavailableItems.length && this.targets.find('scanItem')) {
      this.scanItemTarget.innerHTML = this.renderItems(unavailableItems, true);
      this.unavailableScanItemEstimateTarget.classList.remove('d-none');
      this.availableScanItemEstimateTarget.classList.add('d-none');
    }

    if (availableItems.length === 0) {
      this.availableItemsTarget.closest('.selected-items-group').classList.add('d-none');
    } else {
      this.availableItemsTarget.closest('.selected-items-group').classList.remove('d-none');
    }
    if (unavailableItems.length === 0) {
      this.unavailableItemsTarget.closest('.selected-items-group').classList.add('d-none');
    } else {
      this.unavailableItemsTarget.closest('.selected-items-group').classList.remove('d-none');
    }
  }

  renderItems(items, scan=false) {
    return items.map((item) => {
      return `
        <li class="d-flex gap-2 w-100">
          <span class="hstack gap-2 border bg-light rounded-pill px-3">
            <small class="py-1">
              ${item.label}
            </small>
            <span class="vr"></span>
            <button data-action="${this.identifier}#unchecked" data-${this.identifier}-id-param="${item.id}" type="button" class="btn-close py-1 pill-close" aria-label="Remove ${item.label}"></button>
          </span>
          ${item.duequeueinfo && !scan ? `<span class="text-cardinal d-block align-self-center">${item.duequeueinfo}</span>` : ''}
        </li>
      `;
    }).join('');
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
}
