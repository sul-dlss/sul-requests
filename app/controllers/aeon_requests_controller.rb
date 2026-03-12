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

    requests = sort_aeon_requests(filter_aeon_requests(current_user&.aeon&.draft_requests || []))
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(requests)
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

  def resubmit
    authorize! :update, @aeon_request

    aeon_client.update_request_route(transaction_number: params[:id], status: 'Submitted by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove("request-#{params[:id]}") }
    end
  end

  def edit
    authorize! :update, @aeon_request

    request.variant = :modal if params[:modal]
  end

  def update # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    authorize! :update, @aeon_request

    new_request = aeon_client.update_request(
      @aeon_request.transaction_number,
      AeonClient::RequestData.with_defaults.with(
        appointment_id: aeon_request_params[:appointment_id]&.to_i,
        for_publication: aeon_request_params[:for_publication] == 'yes',
        item_info5: aeon_request_params[:requested_pages],
        special_request: aeon_request_params[:additional_information]
      )
    )

    respond_to do |format|
      format.turbo_stream do
        component = if new_request.draft? && new_request.multi_item_selector?
                      Aeon::RequestGroupItemComponent.new(request: new_request)
                    else
                      Aeon::RequestComponent.new(request: new_request)
                    end
        render turbo_stream: turbo_stream.replace(new_request, component)
      end
      format.html do
        aeon_requests_path = new_request.draft? ? drafts_aeon_requests_path : submitted_aeon_requests_path
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

  private

  def load_aeon_request
    @aeon_request = current_user.aeon.requests.find { |request| request.transaction_number == params[:id].to_i }
  end

  def aeon_request_params
    params.expect(aeon_request: [:appointment_id, :requested_pages, :for_publication, :additional_information])
  end
end
