# frozen_string_literal: true

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  include AeonController

  rescue_from EadClient::Error, with: :handle_ead_client_error

  def new
    authorize! :new, Aeon::Request

    @ead = EadClient.fetch(ead_url_param)
    @ead_url = ead_url_param
    @ead_request = Ead::Request.new(user: current_user, ead: @ead)
  end

  # rubocop:disable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity
  # This is the action triggered by the form submission to create an Aeon request.
  def create
    authorize! :create, Aeon::Request

    # Fetch EAD data to get the actual collection information
    @ead = EadClient.fetch(params[:ead_url])

    items = params[:volumes]&.reject(&:blank?)&.map { |json_str| JSON.parse(json_str) }
    @request = Ead::Request.new(user: current_user, ead: @ead, items:, shipping_option: params[:shipping_option])

    results = @request.create_aeon_requests!

    # Separate successes and failures
    successes, failures = results.partition { |r| r[:success] }

    # Set appropriate flash message based on results
    if failures.empty?
      flash[:notice] = "All #{successes.count} request(s) submitted successfully!"
    elsif successes.empty?
      flash[:error] = "All requests failed: #{failures.map { |f| "#{f[:volume]} (#{f[:error]})" }.join('; ')}"
    else
      flash[:warning] = "#{successes.count} succeeded, #{failures.count} failed: #{failures.pluck(:volume).join(', ')}"
    end

    redirect_to new_archives_request_path(value: params[:ead_url])
  end
  # rubocop:enable Metrics/PerceivedComplexity, Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity

  private

  def ead_url_param
    # Handle both 'value' and 'Value' params for compatibility (Aeon currently accepts Value)
    return params.require(:Value) if params[:Value].present?

    params.require(:value)
  end

  def handle_ead_client_error
    render 'error'
  end
end
