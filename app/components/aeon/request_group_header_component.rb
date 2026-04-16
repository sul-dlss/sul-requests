# frozen_string_literal: true

module Aeon
  # Render a group of requests that share the same title and request type
  class RequestGroupHeaderComponent < ViewComponent::Base
    attr_reader :title, :base_callnumber, :reading_room
    def initialize(title:, base_callnumber:, reading_room: nil)
      @title = title
      @base_callnumber = base_callnumber
      @reading_room = reading_room
    end
  end
end