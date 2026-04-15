# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  include AeonController
  include AeonFilterable
  include AeonSortable

  before_action :load_aeon_request, only: [:edit, :update, :destroy, :resubmit]
  before_action :load_multiple_aeon_requests, only: [:destroy_multiple]
  before_action :set_variant, only: [:drafts, :edit]

  def drafts
    authorize! :read, Aeon::Request

    requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.draft_requests || []))
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
    @appointment = current_user.aeon.appointment_by_id(id: params[:appointment_id]) if params[:appointment_id]
  end

  def cancelled
    authorize! :read, Aeon::Request

    @aeon_requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.cancelled_requests || []))
  end

  def submitted
    authorize! :read, Aeon::Request

    requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.submitted_requests || []))
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
  end

  def completed
    authorize! :read, Aeon::Request

    requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.completed_requests || []))
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
  end

  def resubmit
    authorize! :update, @aeon_request

    aeon_client.update_request_route(transaction_number: params[:id], status: 'Submitted by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("request-#{params[:id]}") }
    end
  end

  def edit
    authorize! :update, @aeon_request
  end

  def update
    authorize! :update, @aeon_request

    @updated_request = Aeon::UpdateRequestService.new(@aeon_request, aeon_request_params).call

    respond_to do |format|
      format.turbo_stream
      format.html do
        aeon_requests_path = updated_request.draft? ? drafts_aeon_requests_path : submitted_aeon_requests_path
        redirect_to aeon_requests_path, notice: 'Request was successfully updated.'
      end
    end
  end

  def destroy
    authorize! :destroy, @aeon_request

    aeon_client.update_request_route(transaction_number: params[:id], status: 'Cancelled by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@aeon_request) }
    end
  end

  def destroy_multiple
    # Authorize each of the individual aeon requests for deletion
    @aeon_requests.each { |aeon_request| authorize! :destroy, aeon_request }
    # Change status of the requests corresponding to these transaction numbers/ids to 'canceled'
    cancel_multiple_requests
    # Render turbo stream removal for each request
    respond_to do |format|
      format.turbo_stream { render turbo_stream: @aeon_requests.map { |aeon_request| turbo_stream.remove(aeon_request) } }
    end
  end

  private

  def set_variant
    request.variant = :sidebar if params[:variant] == 'sidebar'
    request.variant = :modal if params[:modal]
  end

  def load_aeon_request
    @aeon_request = current_user.aeon.requests.find { |request| request.transaction_number == params[:id].to_i }
  end

  def load_multiple_aeon_requests
    request_ids = params[:ids].map(&:to_i)
    @aeon_requests = current_user.aeon.requests.select { |request| request_ids.include?(request.transaction_number) }
  end

  def aeon_request_params
    params.expect(aeon_request: [:appointment_id, :requested_pages, :for_publication, :additional_information])
  end

  def cancel_multiple_requests
    @aeon_requests.each do |aeon_request|
      aeon_client.update_request_route(transaction_number: aeon_request.transaction_number, status: 'Cancelled by User')
    end
  end
end
