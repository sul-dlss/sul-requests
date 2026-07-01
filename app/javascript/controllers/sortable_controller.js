import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['list', 'sortMenu', 'filterMenu', 'observe', 'subgroup']
  static values = {
    sort: String,
    filter: { type: String, default: '' }
  }

  connect() {
    if (!this.sortValue) {
      this.sortValue = this.sortMenuTarget.querySelector('[data-sortable-sort-param]').dataset.sortableSortParam;
    } else {
      this.resort();
      this.refilter();
    }
  }

  debouncedDynamicResort() {
    if (this.debounceTimeout) {
      clearTimeout(this.debounceTimeout);
    }

    // this.sorting = true;
    this.debounceTimeout = setTimeout(() => {
      this.resort();
      this.refilter();
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

  filter(event) {
    event.preventDefault()

    this.filterValue = event.params['filter']
  }

  sortValueChanged() {
    this.resort();
    this.updateSortMenu();
  }

  filterValueChanged() {
    this.refilter();
    this.updateFilterMenu();
  }

  updateSortMenu() {
    if (!this.hasSortMenuTarget) return;

    this.sortMenuTarget.querySelector('.active')?.classList?.remove('active');
    const activeSort =  this.sortMenuTarget.querySelector('[data-sortable-sort-param="' + this.sortValue + '"]');

    activeSort?.classList?.add('active');
    this.sortMenuTarget.querySelector('.dropdown-toggle').textContent = activeSort?.dataset?.sortableLabelParam || 'Sort';
  }

  updateFilterMenu() {
    if (!this.hasFilterMenuTarget) return;

    this.filterMenuTarget.querySelector('.active')?.classList?.remove('active');
    const activeFilter =  this.filterMenuTarget.querySelector('[data-sortable-filter-param="' + this.filterValue + '"]');

    activeFilter?.classList?.add('active');
    this.filterMenuTarget.querySelector('.dropdown-toggle').textContent = activeFilter?.dataset?.sortableLabelParam || 'All requests';
  }

  resort() {
    if (!this.sortValue || !this.hasListTarget) return;

    this.resortChildren(this.listTarget, this.sortValue + 'SortValue');

    this.subgroupTargets.forEach(subgroup => {
      this.resortChildren(subgroup, this.sortValue + 'SortValue');
    });
  }

  refilter() {
    if (!this.hasListTarget) return;

    Array.from(this.listTarget.children).forEach(item => {
      const itemFilterValue = item.dataset.filterValue;

      item.hidden = (this.filterValue == '' || this.filterValue == itemFilterValue) ? false : true;
    });
  }

  resortChildren(target, sortValue) {
    const items = target.children;
    const sortedItems = Array.from(items).sort((a, b) => {
      const aValue = a.dataset[sortValue] || '';
      const bValue = b.dataset[sortValue] || '';

      if (aValue < bValue) return -1;
      if (aValue > bValue) return 1;
      return 0;
    });

    if (Array.from(items).every((item, index) => item === sortedItems[index])) {
      return;
    }

    sortedItems.forEach(item => target.appendChild(item));
  }
}
