# frozen_string_literal: true

# Draws the button for selecting "Scan to PDF" and the associated description of the option
class ScanToPdfButtonComponent < ViewComponent::Base
  def initialize(current_request:)
    @current_request = current_request
  end

  def path
    new_scan_path(@current_request, helpers.request_params)
  end

  def estimate_delivery?
    Settings.features.estimate_delivery
  end

  def single_checked_out_item?
    @current_request.holdings_object.one? && @current_request.holdings_object.all?(&:checked_out?)
  end

  def single_library_value
    single_checked_out_item? ? '' : 'SCAN'
  end
end
