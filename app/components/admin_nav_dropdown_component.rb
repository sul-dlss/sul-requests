# frozen_string_literal: true

# Admin menu in masthead
class AdminNavDropdownComponent < ViewComponent::Base
  attr_reader :masthead_component

  delegate :mediated_locations_for, :main_app, :can?, to: :helpers
  def initialize(masthead_component:)
    @masthead_component = masthead_component
  end

  def render?
    mediated_locations? || site_admin?
  end

  def site_admin?
    can?(:manage, :site)
  end

  def mediated_locations?
    mediated_locations.present?
  end

  def mediated_locations
    mediated_locations_for(PatronRequest.mediateable_origins)
  end
end
