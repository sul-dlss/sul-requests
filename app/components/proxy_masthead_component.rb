# frozen_string_literal: true

# Render the proxy user picker
class ProxyMastheadComponent < ViewComponent::Base
  attr_reader :patron, :selected

  def initialize(patron:, selected: nil)
    @patron = patron
    @selected = selected || patron
  end

  def personal?
    selected == patron
  end

  def render?
    patron.sponsors.any?
  end
end
