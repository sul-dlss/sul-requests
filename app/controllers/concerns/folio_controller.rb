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
    current_user.patron
  end
end
