# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentBriefComponent < Aeon::AppointmentComponent
    with_collection_parameter :appointment

    attr_reader :total_item_limit_percentage

    def initialize(appointment:, total_item_limit_percentage: nil, hide_item_count_badge: false)
      super(appointment:)
      @total_item_limit_percentage = total_item_limit_percentage
      @hide_item_count_badge = hide_item_count_badge
    end

    def hide_item_count_badge?
      @hide_item_count_badge
    end

    def badge_classes
      if total_item_limit_percentage >= 1
        'bg-danger-subtle'
      elsif total_item_limit_percentage >= 0.8
        'bg-warning-subtle'
      else
        'bg-success-subtle text-dark'
      end
    end
  end
end
