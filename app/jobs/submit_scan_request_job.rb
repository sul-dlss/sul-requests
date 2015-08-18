##
# Submit a Scan request to Symphony for processing
class SubmitScanRequestJob < ActiveJob::Base
  queue_as :default

  def perform(request)
    return true unless base_url.present?

    response = client.get('func_request_webservice_new.make_request', request_params(request))

    r = SymphonyResponse.new(JSON.parse(response.body)['request_response'])

    request.symphony_response = r
    request.save
  end

  def request_params(request)
    patron_from_request(request).merge(items_from_request(request)).merge(
      req_type: 'SCAN'
    ).reject { |_, v| v.blank? }
  end

  private

  # rubocop:disable Metrics/AbcSize
  def patron_from_request(request)
    {
      sunet_id: (request.user.webauth if request.user.webauth_user?),
      library_id: request.user.library_id,
      patron_name: (request.user.name if request.user.library_id.blank?),
      patron_email: (request.user.email_address if request.user.library_id.blank?)
    }
  end
  # rubocop:enable Metrics/AbcSize

  def items_from_request(request)
    items = request.barcodes
    items = ['NO_ITEMS'] if items.blank?

    {
      ckey: request.item_id,
      items: items.join('^') + '^',
      home_lib: request.origin
    }
  end

  def client
    @client ||= Faraday.new(url: base_url)
  end

  def base_url
    Settings.symphony_api.url
  end
end
