# frozen_string_literal: true

##
# A utility class to return a note based on a given current location
class CurrentLocationNote
  attr_reader :current_location

  def initialize(current_location)
    @current_location = current_location || ''
  end

  def present?
    checkedout?
  end

  def to_s
    I18n.t('requests.item_selector.checked_out_note') if checkedout?
  end

  def checkedout?
    current_location == 'CHECKEDOUT'
  end
end
