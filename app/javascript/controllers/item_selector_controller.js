import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['items', 'availableItems', 'unavailableItems']
  static values = { selectedItems: Array }

  connect() { }

  change(event) {
    if (event.currentTarget.checked) {
      this.selectedItemsValue = this.selectedItemsValue.concat([event.params]);
    } else {
      this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);
    }
  }

  unchecked(event) {
    event.preventDefault();

    const target = this.itemsTargets.find((item) => item.dataset.itemselectorIdParam === event.params.id)
    if (target) target.checked = false;

    this.selectedItemsValue = this.selectedItemsValue.filter((item) => item.id !== event.params.id);
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

    if (availableItems.length === 0) {
      this.availableItemsTarget.parentElement.classList.add('d-none');
    } else {
      this.availableItemsTarget.parentElement.classList.remove('d-none');
    }
    if (unavailableItems.length === 0) {
      this.unavailableItemsTarget.parentElement.classList.add('d-none');
    } else {
      this.unavailableItemsTarget.parentElement.classList.remove('d-none');
    }
  }

  renderItems(items) {
    return items.map((item) => {
      return `
        <div class="item">
          ${item.label}
          <button data-action="${this.identifier}#unchecked" data-${this.identifier}-id-param="${item.id}">Remove</button>
        </div>
      `;
    }).join('');
  }
}
