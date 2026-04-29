# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentSidebarComponent < Aeon::AppointmentComponent
    with_collection_parameter :appointment
  end
end
