# frozen_string_literal: true

# Mixin for controllers that work with FOLIO data
module FolioController
  extend ActiveSupport::Concern

  included do
    helper_method :patron_or_group
  end

  def current_ability
    @current_ability ||= SiteAbility.new(current_user).merge(PatronAbility.new(current_user.patron))
  end

  def patron_or_group
    current_proxy_group || current_user.patron
  end

  def current_proxy_group
    return @current_proxy_group if defined?(@current_proxy_group)

    return unless session[:proxyFor]

    sponsor = current_user.patron.sponsors.find { |s| s.id == session[:proxyFor] }

    return unless sponsor

    @current_proxy_group = sponsor.proxy_group.with_proxy(current_user.patron)
  end
end
