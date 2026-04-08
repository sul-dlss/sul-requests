import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["availability", "duration", "fieldset"]

  async refreshDateMetadata() {
    const formData = new FormData(this.element);

    const readingRoomId = formData.get('aeon_appointment[reading_room_id]');
    const date = new Date().toISOString().split('T')[0];

    try {
      const response = await fetch(`/aeon_appointments/available/${readingRoomId}/${date}`,
        { headers: { Accept: "application/json" } }
      );

      if (!response.ok) return;

      const data = await response.json();

      const dateField = this.element.querySelector('[name="aeon_appointment[date]"]');
      dateField.min = ((data.slots || [])[0]?.start_time?.split('T') || [])[0];
      this.updateSelectedAppointmentDiv();
    } catch (error) {
      console.error("Error fetching availability data:", error);
    }
  }

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

  refreshAvailability() {
    const formData = new FormData(this.element);

    const date = formData.get('aeon_appointment[date]');
    const readingRoomId = formData.get('aeon_appointment[reading_room_id]');
    const startTime = formData.get('aeon_appointment[start_time]');
    const apptDuration = formData.get('aeon_appointment[duration]');

    if (!date || !readingRoomId) return;

    this.availabilityTarget.src = `/aeon_appointments/available/${readingRoomId}/${date}?selected=${startTime}&duration=${apptDuration}`
  }

  resetFields() {
    this.element.querySelector('input[type=date]').value = '';
    const checkedDuration = document.querySelector('[name="aeon_appointment[duration]"]:checked');
    if (checkedDuration) checkedDuration.checked = false;
    this.updateFormStatus();
    this.updateSelectedAppointmentDiv();
  }


  updateSelectedAppointmentDiv(event) {
    const formData = new FormData(this.element);
    const form_date = formData.get('aeon_appointment[date]');
    if (!form_date) { return }
    const date = new Date(Date.parse(form_date));
    const appointmentDiv = document.querySelector(this.element.dataset.appointmentDiv);
    appointmentDiv.classList.remove('d-none');
    const start_time = formData.get('aeon_appointment[start_time]');
    const duration = formData.get('aeon_appointment[duration]');
    const options = { year: 'numeric', month: 'short', day: 'numeric', timeZone: 'UTC' };
    let text = `${date.toLocaleDateString('en-US', options)}`
    if (start_time && duration) {
      const end_time = this.getEndTime(start_time, duration)
      text += `<i class="bi bi-dot"></i>${start_time} - ${end_time}`
    }
    appointmentDiv.innerHTML = `<div class="d-flex">${text}</div>`;
  }

  getEndTime(start_time, duration) {
    const time_ampm = start_time.split(' ')
    // convert to time decimal 10:30 to 10.5, 10:00 to 10.0
    const start_time_dec = parseFloat(time_ampm[0].replace(':30', '.5').replace(':00', '.0'))
    // get duration in decimal minutes (convert 1800 sec to .5)
    const duration_dec = parseFloat(duration) / 3600;
    // add duration to start time, i.e. 30 min appt (.5) + 10.5 (10:30)
    const end_time = start_time_dec + duration_dec;
    // If appointment goes am to pm (10:30 / 2 hour appt), the am should be pm
    const amPm = (end_time >= 12) ? 'pm' : time_ampm[1];
    // If appointment does from 10am to 1pm, this will be 13 so it needs to be adjusted
    const adjustedEndTime = (end_time >= 13) ? end_time - 12 : end_time;
    // convert from decimal to human time
    return `${adjustedEndTime.toFixed(1).replace('.5', ':30').replace('.0', ':00')} ${amPm}`
  }

  updateFormStatus() {
  const formData = new FormData(this.element);
    if (!formData.get('aeon_appointment[duration]') || !formData.get('aeon_appointment[date]') || !formData.get('aeon_appointment[reading_room_id]')) {
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
    this.updateSelectedAppointmentDiv();
  }
}
