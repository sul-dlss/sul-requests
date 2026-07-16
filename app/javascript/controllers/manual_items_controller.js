import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ['rows', 'template'];

  connect() {
    if (this.rowElements().length === 0) this.createRow();
    else this.rowElements().forEach(row => this.normalizeRow(row));
    this.emitChange();
  }

  addRow(event) {
    event.preventDefault();
    this.createRow();
    this.emitChange();
  }

  removeRow(event) {
    event.preventDefault();
    event.currentTarget.closest('[data-manual-items-row]').remove();
    this.emitChange();
  }

  // Hide rows the user saved for later.
  syncSavedForLater() {
    const savedIds = new Set(
      Array.from(document.querySelectorAll('[data-save-for-later-target="list"] [data-content-id]'))
        .map(el => el.dataset.contentId)
    );

    this.rowElements().forEach(row => {
      row.classList.toggle('d-none', savedIds.has(row.dataset.contentId));
    });
  }

  // Set the row's UUID as both the aeon_item hash key (server-side identity)
  // and data-content-id (cross-controller handle).
  normalizeRow(row) {
    const uuid = row.querySelector('input[type="hidden"]').value;
    row.dataset.contentId = uuid;
    row.querySelectorAll('input').forEach(input => {
      input.name = input.name.replace(/\[aeon_item\]\[[^\]]+\]/, `[aeon_item][${uuid}]`);
    });
  }

  emitChange() {
    const entries = this.rowElements().map(row => ({
      id: row.dataset.contentId,
      title: row.querySelector('input[type="text"]').value,
    }));

    this.dispatch('changed', { detail: { entries } });
  }

  createRow() {
    const fragment = document.importNode(this.templateTarget.content, true);
    const rootNode = fragment.querySelector('[data-manual-items-row]');

    this.rowsTarget.appendChild(rootNode);
    rootNode.querySelector('input[type="hidden"]').value = crypto.randomUUID();
    this.normalizeRow(rootNode);
  }

  rowElements() {
    return Array.from(this.rowsTarget.querySelectorAll('[data-manual-items-row]'));
  }
}
