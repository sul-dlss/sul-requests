# frozen_string_literal: true

###
# Module to group request object validations together
###
module RequestValidations
  extend ActiveSupport::Concern

  included do
    validates :item_id, :origin, :origin_location, presence: true
    validate :requested_holdings_exist,
             :requested_item_is_not_scannable_only,
             on: :create
    validate :needed_date_is_not_in_the_past, on: :create, if: :needed_date
    validate :library_id_exists, on: :create
  end

  protected

  def destination_is_a_pickup_library
    return if check_destination(destination)

    errors.add(:destination, 'is not a valid pickup library')
  end

  # Based on FOLIO or Symphony, will do different check
  def check_destination(destination)
    pickup_destinations.include?(destination)
  end

  def requested_item_is_not_scannable_only
    return unless scannable_only?

    errors.add(
      :base,
      'This item is for in-library use and not available for Request & pickup.'
    )
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
    errors.add(:needed_date, 'Date cannot be earlier than today') if needed_date < Time.zone.today
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def library_id_exists
    return unless user

    # Ensure we don't contact the ILS if we don't need to validate the library ID
    return if user.sso_user? || (requestable_with_name_email? && user.name_email_user?)

    # We require the library ID is on the client side when neccesary
    # required when necessary, so if it's blank here, it's not required
    return if user.library_id.blank?

    errors.add(:library_id, 'This ID was not found in our records') unless user.patron&.exists?
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
