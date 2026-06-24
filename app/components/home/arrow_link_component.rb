# frozen_string_literal: true

module Home
  # Underlined link with a trailing right-arrow icon. Used inside home page cards.
  class ArrowLinkComponent < ViewComponent::Base
    attr_reader :label, :path, :classes

    def initialize(label:, path:, classes: [])
      @label = label
      @path = path
      @classes = classes
    end
  end
end
