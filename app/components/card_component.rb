# frozen_string_literal: true

# Render card
class CardComponent < ViewComponent::Base
  renders_one :pre
  renders_one :title
  renders_one :actions
  renders_one :body, lambda { |classes: [], data: {}, **tag_attributes, &block|
    tag.div(class: ['card-body'] + Array(classes), data: data, **tag_attributes, &block)
  }
  renders_one :footer, lambda { |classes: %w[bg-body-tertiary d-flex justify-content-between align-items-center], &block|
    tag.div(class: %w[card-footer] + Array(classes), &block)
  }
  renders_one :post

  attr_reader :element, :classes, :header_attributes, :margin_class, :tag_options

  def initialize(element: 'div', classes: [], body_classes: [], header_attributes: {}, margin_class: 'mb-4', **tag_options) # rubocop:disable Metrics/ParameterLists
    @element = element
    @classes = Array(classes)
    @body_classes = Array(body_classes)
    @header_attributes = header_attributes
    @margin_class = margin_class
    @tag_options = tag_options
  end

  def header_classes
    @header_classes = %w[card-header d-flex gap-4 justify-content-between align-items-center bg-body-tertiary]
    @header_classes += header_attributes[:classes] if header_attributes[:classes].present?
    @header_classes.join(' ')
  end
end
