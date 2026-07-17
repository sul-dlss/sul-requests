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

  def lead_tag(menu_item)
    return tag.i(class: 'bi bi-record-fill me-1', style: 'font-size: 11px') if selected.id == menu_item.id

    tag.span(class: 'ps-3')
  end
end
