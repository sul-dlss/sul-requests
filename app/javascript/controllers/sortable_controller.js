import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ['list', 'menu']
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

  sort(event) {
    event.preventDefault()

    this.sortValue = event.params['sort']
  }
  
  sortValueChanged() {
    this.resort();
    this.updateMenu();
  }

  updateMenu() {
    this.menuTarget.querySelector('.active')?.classList?.remove('active');
    const activeSort =  this.menuTarget.querySelector('[data-sortable-sort-param="' + this.sortValue + '"]');

    activeSort?.classList?.add('active');
    this.menuTarget.querySelector('.dropdown-toggle').textContent = activeSort?.dataset?.sortableLabelParam || 'Sort';
  }
  
  resort() {
    if (!this.sortValue) return;

    const items = this.listTarget.children;

    const sortedItems = Array.from(items).sort((a, b) => {
      const aValue = a.dataset[this.sortValue + 'SortValue'] || '';
      const bValue = b.dataset[this.sortValue + 'SortValue'] || '';

      if (aValue < bValue) return -1;
      if (aValue > bValue) return 1;
      return 0;
    });

    sortedItems.forEach(item => this.listTarget.appendChild(item));
  }
}
