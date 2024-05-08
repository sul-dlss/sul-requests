import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.hasHoldingsTarget = false;
    this.holdingsTarget = null;
  }

  toggleHoldings() {
    if ( this.element.classList.contains('expanded') ) {
      this.hideRow();
    } else {
      this.showRow();
    }
  }

  showRow() {
    this.addHoldings();
    this.element.classList.add('expanded');
    this.holdingsTarget.classList.remove('d-none');
  }

  hideRow() {
    if (!this.hasHoldingsTarget) return;
    this.element.classList.remove('expanded');
    this.holdingsTarget.classList.add('d-none');
  }

  addHoldings() {
    if (this.hasHoldingsTarget) return;

    this.createHoldingsRow();
  }

  createHoldingsRow() {
    const tr = document.createElement('tr');
    tr.classList.add('holdings');
    const td = document.createElement('td');
    td.colSpan = 7;
    const frame = document.createElement('turbo-frame');
    frame.innerHTML = 'Loading...';
    frame.id = this.element.id + '-holdings';
    frame.src = this.element.dataset.mediateRequest;
    td.append(frame);
    tr.append(td);
    this.element.after(tr);
    this.holdingsTarget = tr;
    this.hasHoldingsTarget = true;
  }
}
