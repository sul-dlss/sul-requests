# frozen_string_literal: true

# Draws the button for selecting "Request & Pickup" and the associated description of the option
class RequestAndPickupButtonComponent < ViewComponent::Base
  def initialize(current_request:)
    @current_request = current_request
  end

  def path
    helpers.delegated_new_request_path(@current_request)
  end

  def scannable_only?
    @current_request.scannable_only?
  end

  def estimate_delivery?
    Settings.features.estimate_delivery && !Settings.features.migration
  end

  def default_pickup_destination
    Settings.ils.bib_model == 'Folio::Instance' ? Settings.folio.default_service_point : Settings.default_pickup_library
  end

  def single_checked_out_item?
    @current_request.holdings_object.one? && @current_request.holdings_object.all?(&:checked_out?)
  end

  def single_destination_value
    single_checked_out_item? ? '' : default_pickup_destination
  end
end
