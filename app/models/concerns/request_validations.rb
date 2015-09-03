###
# Module to group request object validations together
###
module RequestValidations
  extend ActiveSupport::Concern

  included do
    validates :item_id, :origin, :origin_location, presence: true
    validates :item_comment, presence: true, if: :item_commentable?
    validate :requested_holdings_exist
    validate :needed_date_is_not_in_the_past, on: :create
  end

  protected

  def destination_is_a_pickup_library
    return if library_location.pickup_libraries.include?(destination)
    errors.add(:destination, 'is not a valid pickup library')
  end

  # This will currently stil pass if the request has no barcodes.
  # I'm not sure we strongly enforce WHEN requests require barcodes
  # (it seems like it may be variable depending on the record).
  def requested_holdings_exist
    holdings_barcodes = holdings.map(&:barcode)
    return if barcodes.all? { |b| holdings_barcodes.include?(b) }
    errors.add(:base, 'A selected item is not located in the requested location')
  end

  def needed_date_is_not_in_the_past
    errors.add(:base, 'Date cannot be earlier than today') if needed_date && needed_date < Time.zone.today
  end
end
