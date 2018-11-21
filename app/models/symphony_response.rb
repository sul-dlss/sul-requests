# frozen_string_literal: true

##
# Model responses from Symphony requests
class SymphonyResponse
  include ActiveModel::Model

  attr_accessor :req_type, :confirm_email, :usererr_code, :usererr_text, :requested_items

  def items_by_barcode
    (requested_items || []).each_with_object({}) do |i, h|
      h[i['barcode']] = i
    end
  end

  def success?(barcode = nil)
    return false if usererr_code.present?
    return false if items_by_barcode.blank?
    return item_successful?(barcode) if barcode

    successful_barcodes.present?
  end

  def any_error?
    usererr_code.present? || erroneous_barcodes.present?
  end

  def mixed_status?
    erroneous_barcodes.present? && successful_barcodes.present?
  end

  def item_failed?(barcode)
    return unless barcode && items_by_barcode[barcode]

    items_by_barcode[barcode]['msgcode'] && !item_successful?(barcode)
  end

  private

  def item_successful?(barcode = nil)
    return unless barcode && items_by_barcode[barcode]

    success_codes.include?(items_by_barcode[barcode]['msgcode'])
  end

  def successful_barcodes
    items_by_barcode.keys.select do |barcode|
      item_successful?(barcode)
    end
  end

  def erroneous_barcodes
    items_by_barcode.keys.reject do |barcode|
      item_successful?(barcode)
    end
  end

  def success_codes
    SULRequests::Application.config.symphony_success_codes
  end
end
