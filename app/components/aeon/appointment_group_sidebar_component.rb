# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentGroupSidebarComponent < Aeon::AppointmentGroupComponent
    with_collection_parameter :appointment_group
  end
end
