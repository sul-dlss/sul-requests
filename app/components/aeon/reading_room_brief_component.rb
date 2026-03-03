# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class ReadingRoomBriefComponent < ViewComponent::Base
    def initialize(reading_room:)
      @reading_room = reading_room
    end

    attr_reader :reading_room
  end
end
