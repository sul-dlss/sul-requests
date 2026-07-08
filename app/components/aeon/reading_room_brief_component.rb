# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class ReadingRoomBriefComponent < ViewComponent::Base
    def initialize(reading_room:, create_appointment: false)
      @reading_room = reading_room
      @create_appointment = create_appointment
    end

    def create_appointment?
      @create_appointment
    end

    attr_reader :reading_room
  end
end
