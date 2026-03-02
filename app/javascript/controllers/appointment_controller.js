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
    const start_time = formData.get('aeon_appointment[start_time]');

    if (!date || !readingRoomId) return;

    this.availabilityTarget.src = `/aeon_appointments/available/${readingRoomId}/${date}?selected=${start_time}`
  }

  resetFields() {
    this.element.querySelector('input[type=date]').value = '';
    this.availabilityTarget.src = '';
  }

  applyDurationFilter() {
    const formData = new FormData(this.element);
    const apptDuration = formData.get('aeon_appointment[duration]');

    this.element.querySelectorAll('[name="aeon_appointment[start_time]"]').forEach((radio) => {
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
