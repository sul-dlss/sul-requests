# frozen_string_literal: true

###
#  Controller for displaying Aeon requests for a user
###
class AeonRequestsController < ApplicationController
  include AeonController
  include AeonFilterable
  include AeonSortable

  before_action :load_aeon_requests
  before_action :load_filtered_aeon_requests, only: [:index]
  before_action :load_aeon_request_groups
  before_action :load_aeon_request, except: [:index, :destroy_multiple]
  before_action :set_variant, only: [:index, :edit]

  def index
    authorize! :read, Aeon::Request
  end

  def resubmit
    authorize! :update, @aeon_request

    @updated_aeon_request = aeon_client.update_request_route(transaction_number: params[:id], status: 'Submitted by User')

    respond_to do |format|
      format.turbo_stream { update_turbo_stream }
    end
  end

  def redraft
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
        aeon_requests_path = @updated_aeon_request.saved_for_later? ? aeon_requests_path(kind: 'drafts') : aeon_requests_path(kind: 'submitted')
        redirect_to aeon_requests_path, notice: 'Request was successfully updated.'
      end
    end
  end

  def destroy
    authorize! :destroy, @aeon_request

    @updated_aeon_request = aeon_client.update_request_route(transaction_number: params[:id], status: 'Cancelled by User')

    respond_to do |format|
      format.turbo_stream { update_turbo_stream }
    end
  end

  def destroy_multiple
    @salient_requests = @aeon_requests.select { |request| selected_request_ids.include?(request.transaction_number) }

    # Authorize each of the individual aeon requests for deletion
    @salient_requests.each { |aeon_request| authorize! :destroy, aeon_request }

    # Change status of the requests corresponding to these transaction numbers/ids to 'canceled'
    @salient_requests.each do |aeon_request| # rubocop:disable Style/CombinableLoops
      aeon_client.update_request_route(transaction_number: aeon_request.transaction_number, status: 'Cancelled by User')
    end

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def update_turbo_stream # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    @previous_aeon_requests = @aeon_requests
    @next_aeon_requests = sort_aeon_requests(@aeon_requests - [@aeon_request] + [@updated_aeon_request]).sort_by do |x|
      [x.title, x.sort_key]
    end

    @previous_aeon_request_groups = @aeon_request_groups
    @next_aeon_request_groups = Aeon::RequestGrouping.from_requests(@next_aeon_requests)
    @next_draft_aeon_request_groups = Aeon::RequestGrouping.from_requests(@next_aeon_requests.select(&:saved_for_later?).reject(&:digital?))

    if @aeon_request.appointment_id != @updated_aeon_request.appointment_id
      @previous_appointment = @aeon_request.appointment&.tap do |appt|
        appt.requests = @next_aeon_requests.select do |request|
          request.appointment_id == appt.id
        end
      end
    end

    if @updated_aeon_request.activity_id
      @activity = current_user.aeon.activities_with_requests.find do |activity|
        activity.id == @updated_aeon_request.activity_id
      end
      @activity.requests = @activity.requests.reject { |request| request.id == @aeon_request.id }
    end

    @appointment = @updated_aeon_request.appointment&.tap do |appt|
      appt.requests = @next_aeon_requests.select do |request|
        request.appointment_id == appt.id
      end
    end

    render 'update'
  end

  def set_variant
    request.variant = :sidebar if params[:variant] == 'sidebar'
    request.variant = :modal if params[:modal]
  end

  def load_aeon_request
    @aeon_request = @aeon_requests.find { |request| request.transaction_number == params[:id].to_i }
    @aeon_request_group = @aeon_request_groups.find { |request_group| request_group.requests.find { |r| r.id == @aeon_request.id } }
  end

  def load_aeon_requests
    @aeon_requests = [] and return unless current_user&.aeon
    return load_filtered_aeon_requests if params[:kind]

    @aeon_requests = sort_aeon_requests(current_user.aeon.requests)
  end

  def load_filtered_aeon_requests # rubocop:disable Metrics/MethodLength,Metrics/CyclomaticComplexity,Metrics/AbcSize
    @aeon_requests = [] and return unless current_user&.aeon

    @aeon_requests = case params[:kind]
                     when 'drafts'
                       current_user.aeon.draft_requests
                     when 'cancelled'
                       current_user.aeon.cancelled_requests
                     when 'submitted'
                       current_user.aeon.submitted_requests
                     when 'completed'
                       current_user.aeon.completed_requests
                     when 'activity'
                       current_user.aeon.activities_with_requests.map(&:requests).flatten
                     else
                       []
                     end

    @aeon_requests = sort_aeon_requests(filter_aeon_requests(@aeon_requests))
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
end
