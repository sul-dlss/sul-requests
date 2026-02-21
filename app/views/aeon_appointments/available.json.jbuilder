# frozen_string_literal: true

json.max_slot_time @appointment_lengths.max
json.min_slot_time @appointment_lengths.min
json.slots @available_appointments do |appointment_slot|
  json.start_time appointment_slot.start_time
end
