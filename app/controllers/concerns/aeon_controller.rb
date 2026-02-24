# frozen_string_literal: true

# Mixin for controllers that work with Aeon data
module AeonController
  extend ActiveSupport::Concern

  included do
    layout 'application_redesign'
  end

  def current_ability
    @current_ability ||= SiteAbility.new(current_user).merge(AeonAbility.new(current_user.aeon))
  end
end
