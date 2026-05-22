# frozen_string_literal: true

# Render page metadata in a card wrapper
class PillComponent < ViewComponent::Base
  def initialize(tag: 'span', classes: [])
    @tag = tag
    @classes = classes + %w[small fw-medium rounded-pill status-pill]
  end

  def call
    tag.public_send(@tag, content, class: @classes)
  end
end
