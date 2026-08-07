import { Controller } from "@hotwired/stimulus"
import { Dropdown } from "bootstrap";

export default class extends Controller {
  static targets = ["button", "input", "option", "availableOptions"]

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
    if (!this.element.closest('#reading')) return;
    this.element.querySelectorAll('[data-count]').forEach(option => {
      const baseCount = parseInt(option.dataset.count);
      const limit = option.dataset.limit ? parseInt(option.dataset.limit) : 0;
      const inputs = this.element.closest('#reading').querySelectorAll("input[data-appointment-select-target='input']")
      const formCount = Array.from(inputs).filter(input => input.value == option.dataset.appointmentId).length;
      const newCount = baseCount + formCount;
      option.querySelector('.item-count').innerHTML = newCount + " item" + ((newCount) !== 1 ? "s" : "");

      const appointmentFull = limit && newCount >= limit
      option.querySelector('.appointment-full').hidden = !appointmentFull
      if (option.closest('.dropdown-menu')) option.closest('button').disabled = appointmentFull;
      if (appointmentFull) {
        option.classList.add(option.dataset.limitClass);
      } else {
        option.classList.remove(option.dataset.limitClass);
      }
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
    } else {
      this.element.querySelector('.selected')?.classList?.remove('selected');
      this.buttonTarget.textContent = 'Select appointment';
      this.dispatch('change', { detail: { value: '' } });
    }
  }

  optionTargetConnected(option) {
    this.buttonTarget.disabled = false;
    if (this.element.closest('li').matches(':only-child') && (this.element.querySelector(':checked')?.value || "") == "") {
      this.selectItem(option);
    }

    const menu = this.availableOptionsTarget;

    Array.from(menu.children).sort((a, b) => {
      const aKey = a.dataset.sortKey || "";
      const bKey = b.dataset.sortKey || "";
      return aKey.localeCompare(bKey);
    }).forEach(option => menu.appendChild(option));
  }
}
