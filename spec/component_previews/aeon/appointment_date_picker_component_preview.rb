# frozen_string_literal: true

module Aeon
  # Preview at /lookbook/previews/aeon/appointment_date_picker_component
  class AppointmentDatePickerComponentPreview < ViewComponent::Preview
    layout 'lookbook'

    # Default — today forward, no restrictions
    def default; end

    # With a minimum date 2 weeks out
    def with_min_date; end

    # With marked days (existing appointments shown as dots)
    def with_marked_days; end

    # With individual disabled days and a disabled range
    def with_disabled_days; end

    # With weekends disabled
    def with_weekends_disabled; end
  end
end
