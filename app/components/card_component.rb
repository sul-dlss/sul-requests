# frozen_string_literal: true

# Render card
class CardComponent < ViewComponent::Base
  renders_one :pre
  renders_one :title
  renders_one :actions
  renders_one :body
  renders_one :footer
  renders_one :post

  attr_reader :classes, :tag_options

  def initialize(classes: [], **tag_options)
    @classes = Array(classes)
    @tag_options = tag_options
  end
end
