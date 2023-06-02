# frozen_string_literal: true

##
# A utility class to return a note based on a given current location
class CurrentLocationNote
  attr_reader :current_location, :holding

  def initialize(holding)
    @holding = holding
  end

  delegate :present?, to: :to_s

  def to_s
    return I18n.t('requests.item_selector.checked_out_note') if checked_out?
    return I18n.t('requests.item_selector.being_processed_note') if processing?
    return I18n.t('requests.item_selector.missing_note') if missing?
    return I18n.t('requests.item_selector.loan_desk_note') if hold?
  end

  delegate :checked_out?, :hold?, :missing?, :processing?, to: :holding
end
