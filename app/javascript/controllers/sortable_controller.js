import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['list', 'menu', 'observe']
  static values = {
    sort: String
  }

  connect() {
    if (!this.sortValue) {
      this.sortValue = this.menuTarget.querySelector('[data-sortable-sort-param]').dataset.sortableSortParam;
    } else {
      this.resort();
    }
  }

  debouncedDynamicResort() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
    }

    // this.sorting = true;
    this.debounceTimeout = setTimeout(() => {
      this.resort();
    }, 30);
  }

  observeTargetConnected(el) {
    this.observer = new MutationObserver((_mutations => {
      this.debouncedDynamicResort();
    }));

    this.observer.observe(el, { childList: true });
  }

  observeTargetDisconnected() {
    this.observer.disconnect();
    if (this.debounceTimeout) clearTimeout(this.debounceTimeout);
  }

  sort(event) {
    event.preventDefault()

    this.sortValue = event.params['sort']
  }
  
  sortValueChanged() {
    this.resort();
    this.updateMenu();
  }

  updateMenu() {
    if (!this.hasMenuTarget) return;

    this.menuTarget.querySelector('.active')?.classList?.remove('active');
    const activeSort =  this.menuTarget.querySelector('[data-sortable-sort-param="' + this.sortValue + '"]');

    activeSort?.classList?.add('active');
    this.menuTarget.querySelector('.dropdown-toggle').textContent = activeSort?.dataset?.sortableLabelParam || 'Sort';
  }
  
  resort() {
    if (!this.sortValue || !this.hasListTarget) return;

    const items = this.listTarget.children;

    const sortedItems = Array.from(items).sort((a, b) => {
      const aValue = a.dataset[this.sortValue + 'SortValue'] || '';
      const bValue = b.dataset[this.sortValue + 'SortValue'] || '';

      if (aValue < bValue) return -1;
      if (aValue > bValue) return 1;
      return 0;
    });

    // TODO: sort subgroups too.

    if (Array.from(items).every((item, index) => item === sortedItems[index])) {
      return;
    }

    sortedItems.forEach(item => this.listTarget.appendChild(item));
  }
}
