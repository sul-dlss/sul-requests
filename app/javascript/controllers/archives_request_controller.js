import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["volumesDisplay", "requestTypeDisplay"]

  updateVolumesDisplay(event) {
    if (!this.hasVolumesDisplayTarget) return;

    // Get all checked volume checkboxes
    const checkedBoxes = this.element.querySelectorAll('input[name="volumes[]"]:checked');
    
    if (checkedBoxes.length === 0) {
      this.volumesDisplayTarget.innerHTML = '<li class="text-muted">No items selected</li>';
    } else {
      const listItems = Array.from(checkedBoxes)
        .map(cb => `<li>${cb.value}</li>`)
        .join('');
      this.volumesDisplayTarget.innerHTML = listItems;
    }
  }

  updateRequestType(event) {
    if (!this.hasRequestTypeDisplayTarget) return;

    const label = event.target.labels[0]?.textContent.trim() || event.target.value;
    this.requestTypeDisplayTarget.textContent = label;
    this.requestTypeDisplayTarget.classList.remove('text-muted');
  }
}
