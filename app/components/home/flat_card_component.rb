# frozen_string_literal: true

module Home
  # Flat card preset (no shadow, no border, no outer margin) used by home page cards.
  class FlatCardComponent < ::CardComponent
    def initialize(**)
      super(
        classes: %w[shadow-none border-0 rounded-1],
        header_classes: %w[border-bottom-0],
        margin_class: nil,
        **
      )
    end
  end
end
