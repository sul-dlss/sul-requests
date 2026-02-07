# frozen_string_literal: true

###
#  Old requests controller that redirects new requests to the PatronRequestsController
###
class RequestsController < ApplicationController
  def index
    @requests = UserRequestAggregator.new(current_user).all
  end

  def new
    mapped_params = { 'instance_hrid' => new_params[:item_id],
                      'origin_location_code' => new_params[:origin_location],
                      'barcode' => new_params[:barcode] }
    redirect_to(new_patron_request_path(mapped_params))
  end

  protected

  def new_params
    params.require(:origin)
    params.require(:item_id)
    params.require(:origin_location)

    params.permit(:origin, :item_id, :origin_location, :barcode)
  end
end
