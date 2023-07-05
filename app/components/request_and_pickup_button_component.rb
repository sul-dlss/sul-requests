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
    Settings.features.estimate_delivery
  end

  def default_pickup_library
    Settings.default_pickup_library
  end

  def single_checked_out_item?
    @current_request.holdings_object.single_checked_out_item?
  end

  def single_library_value
    single_checked_out_item? ? '' : default_pickup_library
  end
end
