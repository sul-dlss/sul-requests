# frozen_string_literal: true

# Service for going from the ARK url in a FOLIO record to the actual EAD XML url.
class FindingAidLookupService
  def initialize(ark_url)
    @ark_url = ark_url
  end

  def ead_url
    return unless @ark_url.present? && @ark_url.include?('archives.stanford.edu/findingaid/ark:')

    actual_location = http_client.head(@ark_url).url.to_s

    return if actual_location.blank?

    finding_aid_id = actual_location.split('/').last
    "https://archives.stanford.edu/download/#{finding_aid_id}.xml"
  end

  private

  def http_client
    @http_client ||= Faraday.new do |f|
      f.use Faraday::FollowRedirects::Middleware, limit: 3
      f.request :retry, max: 4, interval: 5, backoff_factor: 2
      f.adapter Faraday.default_adapter
    end
  end
end
