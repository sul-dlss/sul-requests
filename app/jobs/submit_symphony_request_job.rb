##
# Rails Job to submit a Scan request to Symphony for processing
class SubmitSymphonyRequestJob < ActiveJob::Base
  queue_as :default

  def perform(request, options = {})
    return true unless enabled?

    response = Command.new(request, options).execute!
    request.symphony_response_data = response
    request.symphony_response_will_change!
    request.save
  end

  def enabled?
    Settings.symphony_api.enabled && Settings.symphony_api.url.present?
  end

  ##
  # Command to submit a Scan request to Symphony for processing
  class Command
    include ActiveSupport::Benchmarkable

    attr_reader :request, :options

    delegate :user, to: :request

    def initialize(request, options = {})
      @request = request
      @options = options
    end

    def execute!
      benchmark "Sending func_request_webservice_new.make_request with #{request_params.inspect}" do
        response = client.get('func_request_webservice_new.make_request', request_params)
        JSON.parse(response.body)['request_response']
      end
    end

    def request_params
      patron_from_request.merge(items_from_request).merge(
        req_type: req_type
      ).reject { |_, v| v.blank? }
    end

    private

    def req_type
      case request
      when Scan
        'SCAN'
      when HoldRecall
        'HOLD'
      when Page, MediatedPage
        'PAGE'
      end
    end

    # rubocop:disable Metrics/AbcSize
    def patron_from_request
      {
        sunet_id: (user.webauth if user.webauth_user?),
        library_id: user.library_id,
        patron_name: (user.name if user.library_id.blank?),
        patron_email: (user.email_address if user.library_id.blank?),
        proxy_group: (user.proxy_access.name if request.proxy?)
      }
    end

    def items_from_request
      {
        ckey: request.item_id,
        items: barcodes.join('^') + '^',
        home_lib: request.origin,
        comments: request.item_comment,
        pickup_lib: (request.destination unless request.is_a? Scan),
        not_needed_after: (request.needed_date.strftime('%m/%d/%Y') if request.needed_date)
      }
    end
    # rubocop:enable Metrics/AbcSize

    def barcodes
      items = options[:barcodes]
      items ||= request.barcodes.reject(&:blank?)
      items = ['NO_ITEMS'] if items.blank?
      items
    end

    def client
      @client ||= Faraday.new(url: base_url)
    end

    def base_url
      Settings.symphony_api.url
    end

    def logger
      Rails.logger
    end
  end
end
