# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  include AeonController
  include AeonFilterable
  include AeonSortable

  before_action :load_aeon_requests
  before_action :load_aeon_request_groups
  before_action :load_aeon_request, except: [:index, :destroy_multiple]
  before_action :set_variant, only: [:index, :edit]

  def index
    authorize! :read, Aeon::Request
  end

  def resubmit
    authorize! :update, @aeon_request

    aeon_client.update_request_route(transaction_number: params[:id], status: 'Submitted by User')
    respond_to do |format|
      format.turbo_stream { render turbo_stream: turbo_stream.remove(@aeon_request) }
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
        aeon_requests_path = updated_request.draft? ? aeon_requests_path(kind: 'drafts') : aeon_requests_path(kind: 'submitted')
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

  def destroy_multiple # rubocop:disable Metrics/AbcSize
    request_ids = params[:ids].map(&:to_i)
    salient_requests = @aeon_requests.select { |request| request_ids.include?(request.transaction_number) }
    # Authorize each of the individual aeon requests for deletion
    salient_requests.each { |aeon_request| authorize! :destroy, aeon_request }
    # Change status of the requests corresponding to these transaction numbers/ids to 'canceled'
    salient_requests.each do |aeon_request| # rubocop:disable Style/CombinableLoops
      aeon_client.update_request_route(transaction_number: aeon_request.transaction_number, status: 'Cancelled by User')
    end
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
    @aeon_request = @aeon_requests.find { |request| request.transaction_number == params[:id].to_i }
    @aeon_request_group = @aeon_request_groups.find { |request_group| request_group.requests.find { |r| r.id == @aeon_request.id } }
  end

  def load_aeon_requests # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
    return [] unless current_user&.aeon

    @aeon_requests = case params[:kind]
                     when 'drafts'
                       current_user.aeon.draft_requests
                     when 'cancelled'
                       current_user.aeon.cancelled_requests
                     when 'submitted'
                       current_user.aeon.submitted_requests
                     when 'completed'
                       current_user.aeon.completed_requests
                     else
                       current_user.aeon.requests
                     end

    @aeon_requests = sort_aeon_requests(filter_aeon_requests(@aeon_requests))
  end

  def load_aeon_request_groups
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(@aeon_requests)
  end

  def aeon_request_params
    params.expect(aeon_request: [:appointment_id, :requested_pages, :for_publication, :additional_information])
  end
end
