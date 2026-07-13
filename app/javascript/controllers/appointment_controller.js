import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["availability", "duration", "fieldset", "selection", "placeholder"]
  static values = {
    availabilityRoute: String
  }

  filterDurationFields() {
    const data = this.fieldsetTarget.dataset;
    const maxDuration = data.maxSlot;
    const minDuration = data.minSlot;
    this.durationTargets.forEach((duration) => {
      const seconds = parseInt(duration.dataset.seconds);
      if (maxDuration < seconds || minDuration > seconds) { duration.classList.add('d-none') }
      else { duration.classList.remove('d-none') }
    });
  }

  refreshAvailability() {
    const formData = new FormData(this.element);

    const date = formData.get('aeon_appointment[date]');
    const startTime = formData.get('aeon_appointment[start_time]');
    const apptDuration = formData.get('aeon_appointment[duration]');

    if (!date) return;

    this.updateFormStatus();

    const url =new URL(this.availabilityRouteValue);
    url.searchParams.append('date', date);
    url.searchParams.append('selected', startTime);
    url.searchParams.append('duration', apptDuration);

    if (this.hasPlaceholderTarget) this.availabilityTarget.replaceChildren(this.availabilityPlaceholder);
    this.availabilityTarget.src = url.toString();
  }

  get availabilityPlaceholder() {
    return this.placeholderTarget.content.cloneNode(true);
  }

  updateBanner() {
    if (!this.hasSelectionTarget) { return }
    // get the text for the updated appointment text
    const formData = new FormData(this.element);
    const form_date = formData.get('aeon_appointment[date]');
    if (!form_date) { return }
    const date = new Date(Date.parse(form_date));
    const start_time =  this.element.querySelector('[name="aeon_appointment[start_time]"]:checked')?.dataset?.timestamp;
    const duration = formData.get('aeon_appointment[duration]');
    const options = { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' };
    let text = `<span>${date.toLocaleDateString('en-US', options)}</span>`
    if (start_time && duration) {
      const formattedTime = this.formatTime(start_time, duration)
      text += `<i class="bi bi-dot"></i><span>${formattedTime}</span>`
    }
    // Update the selection portion
    this.selectionTarget.innerHTML = text;
  }

  formatTime(start_time, duration) {
    const startDate = new Date(parseInt(start_time) * 1000);
    const endDate = new Date(startDate.getTime() + parseInt(duration) * 1000);


    return `
     ${startDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'America/Los_Angeles' })} -
     ${ endDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'America/Los_Angeles' }) }
     `.toLowerCase();
  }

  updateFormStatus() {
    const formData = new FormData(this.element);
    const hasDate = !!formData.get('aeon_appointment[date]');
    const hasDuration = !!formData.get('aeon_appointment[duration]');
    this.availabilityTarget.classList.toggle('form-incomplete', !hasDate || !hasDuration);
  }

  applyDurationFilter() {
    const formData = new FormData(this.element);
    const apptDuration = formData.get('aeon_appointment[duration]');
    this.updateFormStatus();

    this.element.querySelectorAll('[name="aeon_appointment[start_time]"]:not([type="hidden"])').forEach((radio) => {
      const slotLength = radio.dataset.maximumAppointmentLength;

      if (parseInt(slotLength) >= parseInt(apptDuration)) {
        radio.disabled = false;
      } else {
        radio.disabled = true;
        radio.checked = false;
      }
    });
  }
}
