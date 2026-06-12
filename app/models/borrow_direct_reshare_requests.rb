# frozen_string_literal: true

# Model for borrowdirect/reshare requests for a patron.
class BorrowDirectReshareRequests
  attr_reader :patron_university_id

  def initialize(patron_university_id)
    @patron_university_id = patron_university_id
  end

  def requests
    # Ensure ReShare requests are active (not yet in the ILS)
    # and that each ReShare request object's patron_id matches
    # the logged in patron's university_id.
    reshare_requests.select(&:active?)
                    .select { |request| request.patron_id == patron_university_id }
  end

  private

  def reshare_requests
    return [] unless patron_university_id

    request_client.requests(patron_university_id).map do |request|
      ReshareRequest.new(request)
    end
  rescue BorrowDirectReshareClient::BorrowDirectError => e
    Honeybadger.notify(e)
    []
  end

  def request_client
    @request_client ||= BorrowDirectReshareClient.new
  end

  ##
  # Wrap the borrow direct reshare request item JSON in a class
  # so we can give it a similar interface to ILS Requests
  class ReshareRequest
    def initialize(request_json = [])
      @request_json = request_json
    end

    # Request becomes REQ_CHECKED_IN once we receive it (and should show as a request ready for pickup/checkout)
    # Request becomes REQ_REQUEST_COMPLETE once the uesr returns it
    ACTIVE_REQUEST_STATUSES = %w[
      REQ_IDLE
      REQ_VALIDATED
      REQ_SOURCING_ITEM
      REQ_SUPPLIER_IDENTIFIED
      REQ_REQUEST_SENT_TO_SUPPLIER
      REQ_BORROWING_LIBRARY_RECEIVED
      REQ_SHIPPED
      REQ_ERROR
      REQ_END_OF_ROTA
      REQ_INVALID_PATRON
      REQ_EXPECTS_TO_SUPPLY
      REQ_CONDITIONAL_ANSWER_RECEIVED
      REQ_CANCEL_PENDING
      REQ_CANCELLED_WITH_SUPPLIER
      REQ_CANCELLED
      REQ_UNFILLED
      REQ_LOCAL_REVIEW
      REQ_FILLED_LOCALLY
      REQ_UNABLE_TO_CONTACT_SUPPLIER
    ].freeze

    def active?
      ACTIVE_REQUEST_STATUSES.include?(request_status)
    end

    def date_submitted
      Date.parse(@request_json.fetch('dateCreated', nil))
    rescue TypeError, Date::Error => e
      Honeybadger.notify(e)
      nil
    end

    def expiration_date; end

    def fill_by_date; end

    def key
      @request_json.fetch('id', nil)
    end

    def patron_id
      @request_json.fetch('patronIdentifier', nil)
    end

    def service_point; end

    def ready_for_pickup?
      false
    end

    def request_status
      @request_json.dig('state', 'code')
    end

    def sort_key(sort)
      case sort
      when :title
        title
      when :date
        [::Folio::Request::END_OF_DAYS.strftime('%FT%T'), title].join('---')
      else
        ''
      end
    end

    def title
      @request_json.fetch('title', nil)
    end

    def to_partial_path
      'requests/borrow_direct_request'
    end

    def manage_request_link; end
  end
end
