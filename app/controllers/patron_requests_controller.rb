# frozen_string_literal: true

###
#  Controller to handle patron requests (e.g. hold/recall, page, scans, etc)
###
class PatronRequestsController < ApplicationController
  layout 'application_new'
  load_and_authorize_resource instance_name: :request
  helper_method :current_request, :new_params

  def show; end

  def login
    @request = PatronRequest.new(new_params)
    @guest_can_request = sul_purchased_policy.length.positive?
  end

  def new
    current_request.assign_attributes(new_params)
  end

  def create
    @request.patron_id = current_user.patron.id

    if @request.save && @request.submit_to_ils_later
      redirect_to @request
    else
      render 'new'
    end
  end

  protected

  def sul_purchased_policy
    sul_purchased_id = Folio::Types.patron_groups.select { |_k, v| v['group'] == 'sul-purchased' }.keys.first
    @policy_service ||= Folio::CirculationRules::PolicyService.new(patron_groups: [sul_purchased_id])
    current_request.bib_data.items.map { |item| @policy_service.item_request_policy(item)&.dig('requestTypes') }.flatten.uniq || []
  end

  def current_request
    @request
  end

  def new_params
    params.require(:instance_hrid)
    params.require(:origin_location_code)

    params.permit(:instance_hrid, :origin_location_code, :barcode)
  end

  def patron_request_params
    params.require(:patron_request).permit(:patron_email, :instance_hrid, :origin_location_code, :needed_date, :service_point_code)
  end
end
