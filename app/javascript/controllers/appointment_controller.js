import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["availability", "duration", "fieldset", "banner"]

  filterDurationFields() {
    const data = this.fieldsetTarget.dataset;
    const maxDuration = data.maxSlot;
    const minDuration = data.minSlot;
    this.durationTargets.forEach((duration) => {
      const seconds = parseInt(duration.dataset.seconds);
      if (maxDuration < seconds || minDuration > seconds) {
        duration.classList.add('d-none');
        if (duration.querySelector('input').checked){
          const totalTargets = this.durationTargets.length;
          const visibleTargets = this.durationTargets.filter(dt => !dt.classList.contains('d-none'));
          const durationIndex = this.durationTargets.indexOf(duration);
          let visibleIndex = Math.max(durationIndex-(totalTargets-visibleTargets.length), 0);

          // click the closest index to the hidden element
          visibleTargets[visibleIndex].querySelector('input').click();
        }
      } else {
        duration.classList.remove('d-none');
      }
    });
  }

  updateReadingRoom(e) {
    e.preventDefault();
    const formData = new FormData(this.element);
    const reading_room = formData.get('reading_room_id');
    if (!reading_room) return
    const turboFrame = this.element.closest('turbo-frame');
    let newTurboSrc = `/aeon_appointments/new/${reading_room}`
    if (turboFrame.src){
      const urlParams = new URLSearchParams(turboFrame.src.split("?").slice(-1)[0]);
      newTurboSrc += `?modal=${urlParams.get('modal')}`
    }
    turboFrame.src = newTurboSrc
  }

  refreshAvailability() {
    const formData = new FormData(this.element);

    const date = formData.get('aeon_appointment[date]');
    const readingRoomId = formData.get('aeon_appointment[reading_room_id]');
    const startTime = formData.get('aeon_appointment[start_time]');
    const apptDuration = formData.get('aeon_appointment[duration]');

    if (!date) return;

    this.availabilityTarget.src = `/aeon_appointments/available/${readingRoomId}/${date}?selected=${startTime}&duration=${apptDuration}`
  }

  updateBanner() {
    const formData = new FormData(this.element);
    const form_date = formData.get('aeon_appointment[date]');
    if (!form_date) { return }
    const date = new Date(Date.parse(form_date));
    this.bannerTarget.classList.remove('d-none');
    const start_time =  this.element.querySelector('[name="aeon_appointment[start_time]"]:checked')?.dataset?.timestamp;
    const duration = formData.get('aeon_appointment[duration]');
    const options = { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' };
    let text = `${date.toLocaleDateString('en-US', options)}`
    if (start_time && duration) {
      const formattedTime = this.formatTime(start_time, duration)
      text += `<i class="bi bi-dot"></i>${formattedTime}`
    }
    this.bannerTarget.innerHTML = `<div class="d-flex">${text}</div>`;
  }

  formatTime(start_time, duration) {
    const startDate = new Date(parseInt(start_time) * 1000);
    const endDate = new Date(startDate.getTime() + parseInt(duration) * 1000);


    return `
     ${startDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'America/Los_Angeles' })} -
     ${ endDate.toLocaleTimeString('en-US', { hour: 'numeric', minute: '2-digit', hour12: true, timeZone: 'America/Los_Angeles' }) }
     `;
  }

  updateFormStatus() {
  const formData = new FormData(this.element);
    if (!formData.get('aeon_appointment[duration]') || !formData.get('aeon_appointment[date]')) {
      this.availabilityTarget.classList.add('form-incomplete');
    } else {
      this.availabilityTarget.classList.remove('form-incomplete');
    }
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
    this.updateBanner();
  }
}
