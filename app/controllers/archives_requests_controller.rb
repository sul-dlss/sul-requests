# frozen_string_literal: true

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  include AeonController

  rescue_from EadClient::Error, with: :handle_ead_client_error

  def show
    @aeon_requests = Aeon::RequestGrouping.new(current_user.aeon.requests.select { |x| x.reference_number == "UUID:#{params[:id]}" })
  end

  def new
    authorize! :new, Aeon::Request

    @ead = EadClient.fetch(ead_url_param)
    @ead_request = Ead::Request.new(user: current_user, ead: @ead, params: (params[:ead_request] ? new_params : {}))
  end

  # This is the action triggered by the form submission to create an Aeon request.
  def create
    authorize! :create, Aeon::Request

    # Fetch EAD data to get the actual collection information
    @ead = EadClient.fetch(new_params[:ead_url])

    @request = Ead::Request.new(user: current_user,
                                ead: @ead,
                                params: new_params,
                                reference_number: "UUID:#{request.uuid}")

    results = @request.create_aeon_requests!

    # Separate successes and failures
    @successes, @failures = results.partition { |r| r[:success] }
  end

  private

  def new_params
    item_keys = params.dig(:ead_request, :items)&.keys || []
    item_values = [:series, :for_publication, :subseries, :requested_pages, :additional_information, :appointment_id]

    params.expect(ead_request: [:ead_url, :request_type, { volumes: [], items: item_keys.index_with { item_values } }]).tap do |p|
      p['items'] = p['items'].values if p['items'].respond_to?(:values)
    end
  end

  def ead_url_param
    # Handle both 'value' and 'Value' params for compatibility (Aeon currently accepts Value)
    return params.require(:Value) if params[:Value].present?

    params.require(:value)
  end

  def handle_ead_client_error
    render 'error'
  end
end
