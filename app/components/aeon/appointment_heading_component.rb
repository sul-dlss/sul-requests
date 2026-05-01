# frozen_string_literal: true

module Aeon
  # Heading that optionally appends a reading room name after a dot separator.
  class AppointmentHeadingComponent < ViewComponent::Base
    def initialize(reading_room: nil, tag: :h1, classes: %w[d-flex align-items-center mb-0])
      @reading_room = reading_room
      @tag = tag
      @classes = Array(classes)
    end

    attr_reader :reading_room, :tag, :classes
  end
end
