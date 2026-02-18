# frozen_string_literal: true

# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  rescue_from EadClient::Error, with: :handle_ead_client_error

  # Maps from the value in EAD to Aeon's valid site codes
  REPOSITORY_TO_SITE_CODE = {
    'Department of Special Collections and University Archives' => 'SPECUA',
    'Archive of Recorded Sound' => 'ARS',
    'East Asia Library' => 'EASTASIA'
  }.freeze

  def new
    @ead = EadClient.fetch(ead_url_param)
    @ead_url = ead_url_param
  end

  # This is the action triggered by the form submission to create an Aeon request.
  def create
    # Fetch EAD data to get the actual collection information
    @ead = EadClient.fetch(params[:ead_url])

    username = current_user.email_address
    volumes = params[:volumes]&.reject(&:blank?)&.map { |json_str| JSON.parse(json_str) }

    # Submit each volume request and collect results
    results = volumes.map do |volume|
      submit_volume_request(volume, username)
      { volume: volume, success: true }
    rescue StandardError => e
      { volume: volume, success: false, error: e.message }
    end

    # Separate successes and failures
    failures = results.reject { |r| r[:success] }
    successes_count = results.count - failures.count

    # Set appropriate flash message based on results
    if failures.empty?
      flash[:notice] = "All #{successes_count} request(s) submitted successfully!"
    elsif successes_count.zero?
      flash[:error] = "All requests failed: #{failures.map { |f| "#{f[:volume]} (#{f[:error]})" }.join('; ')}"
    else
      flash[:warning] = "#{successes_count} succeeded, #{failures.count} failed: #{failures.pluck(:volume).join(', ')}"
    end

    redirect_to new_archives_request_path(value: params[:ead_url])
  end

  private

  def submit_volume_request(volume, username)
    aeon_client = AeonClient.new

    aeon_client.submit_archives_request(
      username: username,
      title: @ead.title,
      author: @ead.creator,
      call_number: "#{@ead.identifier} #{volume['series']}",
      volume: volume['subseries'],
      aeon_link: @ead.collection_permalink,
      shipping_option: params[:shipping_option],
      identifier: @ead.identifier,
      site: map_repository_to_site_code(@ead.repository)
    )
  end

  def map_repository_to_site_code(repository)
    return nil unless repository

    # TODO: Fallback to SPECUA? Other logic?
    REPOSITORY_TO_SITE_CODE[repository] || 'SPECUA'
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

# rubocop:enable Metrics/PerceivedComplexity
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/CyclomaticComplexity
