# frozen_string_literal: true

# Mixin for controllers that work with FOLIO data
module FolioController
  extend ActiveSupport::Concern

  def current_ability
    @current_ability ||= SiteAbility.new(current_user).merge(PatronAbility.new(current_user.patron))
  end
end
