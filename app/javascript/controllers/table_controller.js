import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [];
  static values = { field: String, asc: Boolean };

  connect() { }

  sort(event) {
    const sortby = event.params.field;

    if(this.fieldValue == sortby) { 
      this.ascValue = !this.ascValue;
    } else {
      this.ascValue = true;
      this.fieldValue = sortby;
    }
    this.element.querySelector('[aria-sort]').removeAttribute('aria-sort')
    event.currentTarget.setAttribute('aria-sort', this.ascValue ? 'ascending' : 'descending')

    const rows = this.rowTargets();
    const sorting = Array.from(rows).sort((a, b) => {
      return (this.getSortField(a) < this.getSortField(b) ? -1 : 1) * (this.ascValue ? 1 : -1)
    });
    this.element.querySelector('tbody').replaceChildren(...sorting);
    event.preventDefault();
  }

  getSortField(element) {
    return element.dataset[`sortby${this.fieldValue}`];
  }

  rowTargets() {
    return this.element.querySelectorAll('tbody > tr');
  }
}
