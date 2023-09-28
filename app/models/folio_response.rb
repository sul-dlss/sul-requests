# frozen_string_literal: true

##
# Model responses from FOLIO requests
class FolioResponse
  SUCCESS_CODES = %w[209 722 S001 P001 P001B P002 P005].freeze

  include ActiveModel::Model

  attr_accessor :req_type, :confirm_email, :usererr_code, :usererr_text, :requested_items

  def blank?
    req_type.blank? && requested_items.blank?
  end

  def items_by_barcode
    (requested_items || []).index_by do |i|
      i['barcode']
    end
  end

  def success?(barcode)
    item_successful?(barcode)
  end

  def all_successful?
    items_by_barcode.any? && items_by_barcode.keys.all? { |barcode| item_successful?(barcode) }
  end

  def all_errored?
    items_by_barcode.any? && items_by_barcode.keys.all? { |barcode| !item_successful?(barcode) }
  end

  def any_successful?
    items_by_barcode.any? && items_by_barcode.keys.any? { |barcode| item_successful?(barcode) }
  end

  def any_error?
    items_by_barcode.any? && items_by_barcode.keys.any? { |barcode| !item_successful?(barcode) }
  end

  def user_error?
    usererr_code.present?
  end

  private

  def item_successful?(barcode)
    SUCCESS_CODES.include?(items_by_barcode.dig(barcode, 'msgcode'))
  end
end
