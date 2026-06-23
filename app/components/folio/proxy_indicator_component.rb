# frozen_string_literal: true

# Render page metadata in a card wrapper
class ProxyIndicatorComponent < ViewComponent::Base
  attr_accessor :proxy, :verb

  def initialize(proxy:, verb: 'Borrowed')
    @proxy = proxy
    @verb = verb
  end

  def render?
    proxy.present?
  end
end
