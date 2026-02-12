# frozen_string_literal: true

# Render the application-specific masthead
class ApplicationMastheadComponent < ViewComponent::Base
  attr_reader :application_name, :classes

  renders_many :nav_items, lambda { |classes: [], &block|
    tag.li(class: ['nav-item'] + Array(classes), &block)
  }

  def initialize(application_name:, classes: [])
    @application_name = application_name
    @classes = Array(classes)
  end
end
