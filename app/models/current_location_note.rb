# frozen_string_literal: true

##
# A utility class to return a note based on a given current location
class CurrentLocationNote
  BEING_PROCESSED_LOCATIONS = %w[ON-ORDER INPROCESS ENDPROCESS BINDERY].freeze

  attr_reader :current_location

  def initialize(current_location)
    @current_location = current_location || ''
  end

  def present?
    return false if current_location.blank?

    checkedout? || being_processed?
  end

  def to_s
    return I18n.t('requests.item_selector.checked_out_note') if checkedout?
    return I18n.t('requests.item_selector.being_processed_note') if being_processed?
  end

  def checkedout?
    current_location == 'CHECKEDOUT'
  end

  def being_processed?
    BEING_PROCESSED_LOCATIONS.include?(current_location)
  end
end
