# frozen_string_literal: true

# Render card
class CardComponent < ViewComponent::Base
  renders_one :pre
  renders_one :title
  renders_one :actions
  renders_one :body
  renders_one :footer
  renders_one :post

  attr_reader :element, :classes, :tag_options

  def initialize(element: 'div', classes: [], body_classes: [], **tag_options)
    @element = element
    @classes = Array(classes)
    @body_classes = Array(body_classes)
    @tag_options = tag_options
  end
end
