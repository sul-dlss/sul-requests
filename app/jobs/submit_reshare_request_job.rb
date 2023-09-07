# frozen_string_literal: true

##
# Background job to look up an item to request in Reshare.
# If Reshare has the item and we start a request to Reshare .
# If Reshare does not have it or we cannot succesfully request it, trigger the normal request.
class SubmitReshareRequestJob < ApplicationJob
  discard_on ActiveRecord::RecordNotFound do |job, _error|
    Honeybadger.notify(
      "Attempted to call Reshare for Request with ID #{job.request_id}, but no such Request was found."
    )
  end

  def perform(request_id)
    request = Request.find(request_id)

    Sidekiq.logger.info("Started SubmitReshareRequestJob for request #{request_id}")

    begin
      make_reshare_or_ils_request(request)
    rescue StandardError => e
      Honeybadger.notify("Reshare Request failed for #{request_id} with #{e}. Submitted to the ILS instead.")

      request.send_to_ils_now!
    end

    Sidekiq.logger.info("Completed SubmitReshareRequestJob for request #{request_id}")
  end

  def make_reshare_or_ils_request(request)
    reshare_vufind_item = ReshareVufindWrapper.new(request)

    if request.user.patron.borrow_direct_eligible? && reshare_vufind_item.requestable?
      request.reshare_vufind_response_data = reshare_vufind_item.as_json
      request.via_borrow_direct = true
      request.save

      # Since we found the item to request, we can send a request to IPLC. We defer it to a background job
      # to make error handling easier.
      SubmitIplcListenerJob.perform_later(request.id,
                                          reshare_vufind_item.instance_uuid,
                                          reshare_vufind_item.instance_title)
    else
      request.send_to_ils_now!
    end
  end

  # Basic client for wrapping Reshare's Vufind search API.
  class ReshareVufindWrapper
    attr_reader :request

    delegate :bib_data, to: :request

    # @param request [HoldRecall]
    # @param isbn [String]
    def initialize(request = nil, isbn: nil)
      @request = request
      @isbn = isbn
    end

    # @return [String] the reshare instance UUID for the instance we want to request
    def instance_uuid
      loanable_record['id']
    end

    # @return [String] the reshare instance title for the instance we want to request
    def instance_title
      loanable_record['title']
    end

    # @return [Boolean] whether the item is requestable in Reshare
    def requestable?
      return false if requested_isbn.blank?

      loanable_record.present?
    end

    def as_json(_options = nil)
      {
        requestable: requestable?,
        response: vufind_response,
        instance_uuid:,
        instance_title:,
        requested_isbn:
      }
    end

    private

    def vufind_response
      @vufind_response ||= JSON.parse(vufind_request.body.to_s)
    end

    def requested_isbn
      Array(@isbn || bib_data&.isbn).first
    end

    def loanable_record
      vufind_response['records']&.find { |record| record['lendingStatus'].include? 'LOANABLE' }
    end

    def vufind_request
      params = vufind_request_params

      raise ArgumentError, 'No ISBN provided' if params[:lookfor].blank?

      HTTP.get("#{Settings.borrow_direct.reshare_vufind_url}/api/v1/search", params:)
    end

    # We try to match on the requested item's first ISBN; this is behavior inherited from
    # the relais-based borrow direct implementation.
    def vufind_request_params
      {
        lookfor: requested_isbn,
        'field[]': ['id', 'title', 'lendingStatus'],
        type: 'ISN',
        page: 1,
        sort: 'relevance',
        limit: 20,
        prettyPrint: false,
        lng: 'en'
      }
    end
  end
end
