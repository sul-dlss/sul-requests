# frozen_string_literal: true

module Aeon
  # Render aeon apointment card
  class AppointmentBriefComponent < Aeon::AppointmentComponent
    with_collection_parameter :appointment

    attr_reader :total_item_limit_percentage

    def initialize(appointment:, total_item_limit_percentage: nil)
      super(appointment:)
      @total_item_limit_percentage = total_item_limit_percentage
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
