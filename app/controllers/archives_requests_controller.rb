# frozen_string_literal: true

# rubocop:disable Metrics/PerceivedComplexity
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/CyclomaticComplexity

##
# Controller for handling archives requests with EAD XML data
class ArchivesRequestsController < ApplicationController
  rescue_from EadClient::Error, with: :handle_ead_client_error

  def show
    @ead = EadClient.fetch(ead_url_param)
    @ead_url = ead_url_param
  end

  # This is the action triggered by the form submission to create an Aeon request.
  def submit_to_aeon
    # Fetch EAD data to get the actual collection information
    @ead = EadClient.fetch(params[:ead_url])

    username = current_user.sunetid.present? ? "#{current_user.sunetid}@stanford.edu" : current_user.email
    # volumes = params[:volumes]&.reject(&:blank?)
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

    redirect_to archives_request_path(value: params[:ead_url])
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
      site: params[:site],
      repository: @ead.repository_contact&.dig(:publisher) || @ead.repository
    )
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
