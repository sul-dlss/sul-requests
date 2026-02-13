import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["availability"]

  connect() {
  }

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

  refreshAvailability() {
    const formData = new FormData(this.element);

    const date = formData.get('aeon_appointment[date]');
    const readingRoomId = formData.get('aeon_appointment[reading_room_id]');
    const start_time = formData.get('aeon_appointment[start_time]');

    if (!date || !readingRoomId) return;

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
