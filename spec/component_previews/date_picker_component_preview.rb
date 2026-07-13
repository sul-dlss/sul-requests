# frozen_string_literal: true

# Preview at /lookbook/previews/date_picker_component
class DatePickerComponentPreview < ViewComponent::Preview
  layout 'lookbook'

  # Default — today forward, no restrictions
  def default; end

  def with_reading_room_defaults; end

  # With a minimum date 2 weeks out
  def with_min_date; end

  # With marked days (existing appointments shown as dots)
  def with_marked_days; end

  # With individual disabled days and a disabled range
  def with_disabled_days; end

  # With weekends disabled
  def with_weekends_disabled; end
end
