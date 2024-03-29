# frozen_string_literal: true

###
#  Controller to handle patron requests (e.g. hold/recall, page, scans, etc)
###
class PatronRequestsController < ApplicationController
  layout 'application_new'
  load_and_authorize_resource instance_name: :request
  helper_method :current_request, :new_params

  def show; end

  def new
    current_request.assign_attributes(new_params)
  end

  def create; end

  protected

  def current_request
    @request
  end

  def new_params
    params.require(:instance_hrid)
    params.require(:origin_location_code)

    params.permit(:instance_hrid, :origin_location_code, :barcode)
  end

  def patron_request_params
    params.require(:patron_request).permit(:patron_email, :instance_hrid, :needed_date, :service_point_code)
  end
end
