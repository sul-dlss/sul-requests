# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  include AeonController
  include AeonFilterable
  include AeonSortable

  before_action :load_aeon_requests
  before_action :filter_and_sort_aeon_requests, only: [:index]
  before_action :load_aeon_request_groups
  before_action :load_aeon_request, except: [:index, :destroy_multiple, :update_multiple]
  before_action :set_variant, only: [:index, :edit]

  def index
    authorize! :read, Aeon::Request

    render 'async' and return if params[:async]
  end

  def save_for_later
    authorize! :update, @aeon_request

    request_field = @aeon_request.activity? ? 'activity_id' : 'appointment_id'
    @updated_aeon_request = Aeon::UpdateRequestService.new(@aeon_request, { "#{request_field}": nil, status: 'Awaiting User Review' }).call

    respond_to do |format|
      format.turbo_stream { update_turbo_stream }
    end
  end

  def edit
    authorize! :update, @aeon_request
  end

  def update
    authorize! :update, @aeon_request

    @updated_aeon_request = Aeon::UpdateRequestService.new(@aeon_request, aeon_request_params).call

    respond_to do |format|
      format.turbo_stream { update_turbo_stream }
      format.html do
        kind = @updated_aeon_request.saved_for_later? ? 'saved_for_later' : 'submitted'
        redirect_to aeon_requests_path(kind:), notice: 'Request was successfully updated.'
      end
    end
  end

  def update_multiple # rubocop:disable Metrics/AbcSize
    @appointment = current_user.aeon.appointments.find(params[:appointment_id])

    authorize! :update, @appointment

    saved_for_later_requests_to_update = @aeon_requests.find(Array(params[:items_added])).saved_for_later
    submitted_requests_to_update = @aeon_requests.find(Array(params[:items_removed])).submitted

    authorize_all!(saved_for_later_requests_to_update, :update)
    authorize_all!(submitted_requests_to_update, :update)

    updated_requests = process_items(saved_for_later_requests_to_update, appointment_id: @appointment.id)
    updated_requests += process_items(submitted_requests_to_update, appointment_id: nil)

    respond_to do |format|
      format.turbo_stream { update_turbo_stream(updated_requests: updated_requests) }
    end
  end

  def destroy
    authorize! :destroy, @aeon_request

    @updated_aeon_request = Aeon::UpdateRequestService.new(@aeon_request, { status: 'Cancelled by User' }).call

    respond_to do |format|
      format.turbo_stream { update_turbo_stream }
    end
  end

  def destroy_multiple
    @salient_requests = @aeon_requests.find(selected_request_ids)

    # Authorize each of the individual aeon requests for deletion
    authorize_all!(@salient_requests, :destroy)

    # Change status of the requests corresponding to these transaction numbers/ids to 'canceled'
    updated_requests = process_items(@salient_requests, { status: 'Cancelled by User' })

    respond_to do |format|
      format.turbo_stream { update_turbo_stream(updated_requests: updated_requests) }
    end
  end

  private

  def process_items(requests, updated_params = {})
    requests.map do |request|
      Aeon::UpdateRequestService.new(request, updated_params).call
    end
  end

  def update_turbo_stream(updated_requests: [@updated_aeon_request])
    @update_response = Aeon::UpdateResponseService.new(@aeon_requests, updated_requests)

    render 'update'
  end

  def set_variant
    request.variant = :sidebar if params[:variant] == 'sidebar'
    request.variant = :modal if params[:modal]
  end

  def load_aeon_request
    @aeon_request = @aeon_requests.find(params[:id])
  end

  def load_aeon_requests
    @aeon_requests = if params[:kind] == 'activity'
                       current_user.aeon.own_and_activity_requests.for_activities
                     elsif action_name == 'index'
                       current_user.aeon.requests
                     else
                       current_user.aeon.own_and_activity_requests
                     end
  end

  def filter_and_sort_aeon_requests # rubocop:disable Metrics/MethodLength
    @aeon_requests = filter_aeon_requests(@aeon_requests)

    @aeon_requests = case params[:kind]
                     when 'saved_for_later'
                       @aeon_requests.saved_for_later
                     when 'cancelled'
                       @aeon_requests.cancelled
                     when 'submitted'
                       @aeon_requests.submitted
                     when 'completed'
                       @aeon_requests.completed
                     else
                       @aeon_requests
                     end

    @aeon_requests = sort_aeon_requests(@aeon_requests)
  end

  def load_aeon_request_groups
    @aeon_request_groups = Aeon::RequestGrouping.from_requests(@aeon_requests)
  end

  def aeon_request_params
    params.expect(aeon_request: [:appointment_id, :requested_pages, :for_publication, :additional_information])
  end

  def selected_request_ids
    params.expect(ids: []).map(&:to_i)
  end

  def authorize_all!(requests, action)
    requests.each { |request| authorize! action, request }
  end
end
