# frozen_string_literal: true

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  include AeonController

  before_action :load_patron_request, only: [:new, :create]
  before_action :authorize_new_request, only: [:new]
  rescue_from EadClient::Error, with: :handle_ead_client_error

  def show
    @patron_request = current_user.patron_requests.find(params[:id])
    @aeon_requests = Aeon::RequestGrouping.new(current_user.aeon.requests.select do |x|
      x.reference_number == @patron_request.to_global_id.to_s
    end)
  end

  def new; end

  # This is the action triggered by the form submission to create an Aeon request.
  def create
    authorize! :create, Aeon::Request

    @patron_request.save!

    @patron_request.submit_later

    redirect_to archives_request_path(@patron_request.id)
  end

  private

  def authorize_new_request
    return render 'login' unless current_user.email_address

    authorize! :new, Aeon::Request
  end

  def new_params
    return {} unless params[:patron_request]

    item_keys = params.dig(:patron_request, :items)&.keys || []
    item_values = [:series, :for_publication, :subseries, :requested_pages, :additional_information, :appointment_id]

    params.expect(patron_request: [:ead_url, :request_type, { volumes: [], items: item_keys.index_with { item_values } }]).tap do |p|
      p['items'] = p['items'].values if p['items'].respond_to?(:values)
    end
  end

  def load_patron_request
    @patron_request = PatronRequest.new(user: current_user, ead_url: ead_url_param,
                                        **new_params.to_h.transform_keys({ items: :aeon_item, volumes: :barcodes }.with_indifferent_access))
  end

  def ead_url_param
    return params.dig(:patron_request, :ead_url) if params[:patron_request]
    # Handle both 'value' and 'Value' params for compatibility (Aeon currently accepts Value)
    return params.require(:Value) if params[:Value].present?

    params.require(:value)
  end

  def handle_ead_client_error
    render 'error'
  end
end
