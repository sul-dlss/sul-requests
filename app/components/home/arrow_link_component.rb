# frozen_string_literal: true

module Home
  # Underlined link with a trailing right-arrow icon. Used inside home page cards.
  class ArrowLinkComponent < ViewComponent::Base
    attr_reader :label, :path

    def initialize(label:, path:)
      @label = label
      @path = path
    end
  end
end
