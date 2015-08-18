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
end
