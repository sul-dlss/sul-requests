# frozen_string_literal: true

json.slots @available_appointments do |appointment_slot|
  json.start_time appointment_slot.start_time
end
