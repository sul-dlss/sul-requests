# frozen_string_literal: true

# Render page metadata in a card wrapper
class PillComponent < ViewComponent::Base
  def initialize(tag: 'span', classes: [], id: nil)
    @tag = tag
    @classes = classes + %w[small fw-medium rounded-pill status-pill text-nowrap]
    @id = id
  end

  def call
    tag.public_send(@tag, content, class: @classes, id: @id)
  end
end
