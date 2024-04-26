import { Controller } from "@hotwired/stimulus";
import { Toast } from 'bootstrap';

export default class extends Controller {
  static targets = ['items', 'toast', 'availableItems', 'unavailableItems', 'scanItem', 'unavailableScanItemEstimate', 'availableScanItemEstimate']
  static values = { selectedItems: Array }

  connect() { }

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

  sort(event) {
    const target = event.target.tagName == 'BUTTON' ? event.target.parentElement : event.target;
    const sortby = target.dataset.sortfield;
    const isAsc = target.dataset.sortasc == 'true' ? true : false;
    target.dataset.sortasc = !isAsc;
    this.element.querySelector('[aria-sort]').removeAttribute('aria-sort')
    target.setAttribute('aria-sort', isAsc ? 'descending' : 'ascending')
    const rows = this.element.querySelectorAll("[id^='row']");
    const sorting = Array.from(rows).sort((a, b) => {
      return (this.getSortField(a, sortby) < this.getSortField(b, sortby) ? -1 : 1) * (isAsc ? 1 : -1)
    });
    this.element.querySelector('tbody').innerHTML = sorting.map(elem => elem.outerHTML).join("");
    event.preventDefault();
  }

  getSortField(element, sortby) {
    return element.dataset[`sortby${sortby}`];
  }

  showRemovalToast(item) {
    this.toastTarget.querySelector('.btn').dataset.itemselectorIdParam = item.id;

    Toast.getOrCreateInstance(this.toastTarget).show();
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
      const itemstatus = this.unavailableScanItemEstimateTarget.querySelector('#item-status');
      if (unavailableItems[0].duequeueinfo) {
        itemstatus.innerHTML = `Item status: ${unavailableItems[0].duequeueinfo}`
        itemstatus.classList.remove('d-none');
      } else {
        itemstatus.classList.add('d-none');
      }
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
}
