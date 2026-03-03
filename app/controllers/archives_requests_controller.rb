# frozen_string_literal: true

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  include AeonController

  before_action :load_ead_request, only: [:new, :create]
  before_action :authorize_new_request, only: [:new]
  rescue_from EadClient::Error, with: :handle_ead_client_error

  def show
    @aeon_requests = Aeon::RequestGrouping.new(current_user.aeon.requests.select { |x| x.reference_number == "UUID:#{params[:id]}" })
  end

  def new; end

  # This is the action triggered by the form submission to create an Aeon request.
  def create # rubocop:disable Metrics/AbcSize
    authorize! :create, Aeon::Request

    results = @ead_request.create_aeon_requests!

    successes, failures = results.partition { |r| r[:success] }

    # Set appropriate flash message based on results
    if failures.empty?
      flash[:notice] = "All #{successes.count} request(s) submitted successfully!"
    elsif successes.empty?
      flash[:error] = "All requests failed: #{failures.map { |f| "#{f[:volume]} (#{f[:error]})" }.join('; ')}"
    else
      flash[:warning] = "#{successes.count} succeeded, #{failures.count} failed: #{failures.pluck(:volume).join(', ')}"
    end

    redirect_to archives_request_path(request.uuid)
  end

  private

  def authorize_new_request
    return render 'login' unless current_user.email_address

    authorize! :new, Aeon::Request
  end

  def new_params
    return {} unless params[:ead_request]

    item_keys = params.dig(:ead_request, :items)&.keys || []
    item_values = [:series, :for_publication, :subseries, :requested_pages, :additional_information, :appointment_id]

    params.expect(ead_request: [:ead_url, :request_type, { volumes: [], items: item_keys.index_with { item_values } }]).tap do |p|
      p['items'] = p['items'].values if p['items'].respond_to?(:values)
    end
  end

  def load_ead_request
    @ead_request = PatronRequest.new(user: current_user, ead_url: ead_url_param,
                                     **new_params.to_h.transform_keys({ items: :aeon_item, volumes: :barcodes }.with_indifferent_access))
  end

  def ead_url_param
    return params.dig(:ead_request, :ead_url) if params[:ead_request]
    # Handle both 'value' and 'Value' params for compatibility (Aeon currently accepts Value)
    return params.require(:Value) if params[:Value].present?

    params.require(:value)
  end

  def handle_ead_client_error
    render 'error'
  end
end
