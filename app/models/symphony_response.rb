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

  private

  def item_successful?(barcode)
    success_codes.include?(items_by_barcode.dig(barcode, 'msgcode'))
  end

  def success_codes
    SULRequests::Application.config.symphony_success_codes
  end
end
