# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  include AeonController
  include AeonFilterable
  include AeonSortable

  before_action :load_aeon_request, only: [:edit, :update, :destroy, :resubmit]

  def drafts
    authorize! :read, Aeon::Request

    @aeon_requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.draft_requests || []))
  end

  def cancelled
    authorize! :read, Aeon::Request

    @aeon_requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.cancelled_requests || []))
  end

  def submitted
    authorize! :read, Aeon::Request

    @aeon_requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.submitted_requests || []))
  end

  def resubmit
    authorize! :update, @aeon_request

    AeonClient.new.update_request_route(transaction_number: params[:id], status: 'Submitted by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("request-#{params[:id]}") }
    end
  end

  def edit
    authorize! :update, @aeon_request
  end

  def update
    authorize! :update, @aeon_request

    AeonClient.new.update_request(
      @aeon_request.transaction_number,
      AeonClient::RequestData.with_defaults.with(
        for_publication: aeon_request_params.dig(:item, :for_publication) == 'Yes',
        item_info5: aeon_request_params.dig(:item, :requested_pages),
        special_request: aeon_request_params.dig(:item, :additional_information)
      )
    )
  end

  def destroy
    authorize! :destroy, @aeon_request

    AeonClient.new.update_request_route(transaction_number: params[:id], status: 'Cancelled by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("request-#{params[:id]}") }
    end
  end

  private

  def load_aeon_request
    @aeon_request = current_user.aeon.requests.find { |request| request.transaction_number == params[:id].to_i }
  end

  def aeon_request_params
    params.expect(aeon_request: { item: [:requested_pages, :for_publication, :additional_information] })
  end
end
