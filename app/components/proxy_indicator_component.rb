# frozen_string_literal: true

# Render page metadata in a card wrapper
class ProxyIndicatorComponent < ViewComponent::Base
  attr_accessor :proxy

  def initialize(proxy:)
    @proxy = proxy
  end

  def render?
    proxy.present?
  end
end
