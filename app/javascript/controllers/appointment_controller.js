import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["availability"]

  connect() {
  }

  refreshAvailability() {
    const formData = new FormData(this.element);

    const date = formData.get('aeon_appointment[date]');
    const readingRoomId = formData.get('aeon_appointment[reading_room_id]');
    const start_time = formData.get('aeon_appointment[start_time]');

    this.availabilityTarget.src = `/aeon_appointments/available/${readingRoomId}/${date}?selected=${start_time}`
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
