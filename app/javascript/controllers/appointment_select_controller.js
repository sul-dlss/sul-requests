import { Controller } from "@hotwired/stimulus"
import { Dropdown } from "bootstrap";

export default class extends Controller {
  static targets = ["button", "input", "option"]

  connect() {
    this.updateSelected();
  }

  select(event) {
    event.preventDefault();

    const li = event.currentTarget.closest('li');
    this.selectItem(li);

    new Dropdown(this.element).hide();
  }

  updateItemCounts() {
    this.element.querySelectorAll('[data-count]').forEach(option => {
      const baseCount = parseInt(option.dataset.count);

      const formCount = this.element.closest('#reading-accordion').querySelectorAll("input[value='" + option.dataset.appointmentId + "']").length;

      const newCount = baseCount + formCount;

      option.innerHTML = newCount + " item" + ((newCount) !== 1 ? "s" : "");
    });
  }

  selectItem(element) {
    this.element.querySelector('.selected')?.classList?.remove('selected');
    element.classList.add('selected');

    this.inputTarget.value = element.dataset.value;
    this.inputTarget.dispatchEvent(new Event('input', { bubbles: true }));

    this.updateSelected();

    this.dispatch('change', { detail: { value: this.inputTarget.value } });
  }

  updateSelected() {
    const selectedOption = this.element.querySelector(`[data-value="${this.inputTarget.value}"]`);
    if (selectedOption) {
      this.buttonTarget.innerHTML = selectedOption.querySelector('.label-value').innerHTML;
    }
  }

  optionTargetConnected(option) {
    if (this.element.closest('li').matches(':only-child') && (this.element.querySelector(':checked')?.value || "") == "") {
      this.selectItem(option);
    }

    const menu = this.element.querySelector('menu');

    Array.from(menu.children).sort((a, b) => {
      const aKey = a.dataset.sortKey || "";
      const bKey = b.dataset.sortKey || "";
      return aKey.localeCompare(bKey);
    }).forEach(option => menu.appendChild(option));
  }
}
