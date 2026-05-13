# frozen_string_literal: true

# Render card
class CardComponent < ViewComponent::Base
  renders_one :pre
  renders_one :title
  renders_one :actions
  renders_one :body, lambda { |classes: [], &block|
    tag.div(class: ['card-body'] + Array(classes), &block)
  }
  renders_one :footer, lambda { |classes: %w[bg-body-tertiary d-flex justify-content-between align-items-center], &block|
    tag.div(class: %w[card-footer] + Array(classes), &block)
  }
  renders_one :post

  attr_reader :element, :classes, :tag_options

  def initialize(element: 'div', classes: [], body_classes: [], **tag_options)
    @element = element
    @classes = Array(classes)
    @body_classes = Array(body_classes)
    @tag_options = tag_options
  end
end
