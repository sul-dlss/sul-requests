# frozen_string_literal: true

##
# Background job to send requests to BorrowDirect.
# If BorrowDirect has the item and we succesfully request it save that response.
# If BorrowDirect does not have it or we cannot succesfully request it, trigger the normal Symphony request.
class SubmitBorrowDirectRequestJob < ApplicationJob
  def perform(request_id)
    request = find_request(request_id)
    return true unless request

    Sidekiq::Logging.logger.info("Started SubmitBorrowDirectRequestJob for request #{request_id}")

    begin
      make_borrow_direct_or_symphony_request(request)
    rescue BorrowDirect::Error => e
      Honeybadger.notify("BorrowDirect Request failed for #{request_id} with #{e}. Submitted to Symphony instead.")

      SubmitSymphonyRequestJob.perform_now(request_id)
    end

    Sidekiq::Logging.logger.info("Completed SubmitBorrowDirectRequestJob for request #{request_id}")
  end

  def find_request(request_id)
    Request.find(request_id)
  rescue ActiveRecord::RecordNotFound
    Honeybadger.notify(
      "Attempted to call BorrowDirect for Request with ID #{request_id}, but no such Request was found."
    )
  end

  def make_borrow_direct_or_symphony_request(request)
    borrow_direct_item = BorrowDirectWrapper.new(request)

    if borrow_direct_item.requestable? && (response = borrow_direct_item.request_item).present?
      request.borrow_direct_response_data = response
      request.via_borrow_direct = true
      request.save
      request.send_approval_status!
    else
      SubmitSymphonyRequestJob.perform_now(request.id)
    end
  end

  ##
  # A simple wrapper class around the BorrowDirect gem
  class BorrowDirectWrapper
    attr_reader :api_pickup_locations, :auth_id, :request

    delegate :searchworks_item, :user, to: :request
    delegate :isbn, to: :searchworks_item
    delegate :library_id, to: :user

    def initialize(request)
      @request = request
    end

    # An item is requestable if there is search criteria, and when
    # we find an item using that search criteria the API says it is requestable
    def requestable?
      search_criteria.values.any?(&:present?) && finder.requestable?
    end

    # Returns false if the Borrow Direct request was unsuccessful,
    # otherwise returns the BorrowDirect response itself
    def request_item
      return false unless request_success?

      request_item_response
    end

    private

    # If the response includes a RequestNumber it was successful
    def request_success?
      request_item_response['RequestNumber'].present?
    end

    # If we have an auth_id (set by the finder), use that so we don't
    # have to duplicate the authentication request to the API
    def request_item_response
      @request_item_response ||= if auth_id.present?
                                   request_client
                                     .with_auth_id(auth_id)
                                     .request_item_request(pickup_library, **search_criteria)
                                 else
                                   request_client.request_item_request(pickup_library, **search_criteria)
                                 end
    end

    def finder
      @finder ||= find_client.find(**search_criteria).tap do |response|
        @api_pickup_locations = response.try(:pickup_locations)
        @auth_id = response.try(:auth_id)
      end
    end

    def search_criteria
      { isbn: Array.wrap(isbn).first }
    end

    def find_client
      BorrowDirect::FindItem.new(library_id)
    end

    def request_client
      BorrowDirect::RequestItem.new(library_id)
    end

    # return the requested pickup destination label if there are no locations set by the API
    # return the requested pickup destination label if the locations set by the API include the requested label
    # return the default pickup destination label otherwise (and notify Honeybadger)
    def pickup_library
      requested_pickup_library = library_config[request.destination]
      return requested_pickup_library if api_pickup_locations.blank? ||
                                         api_pickup_locations.include?(requested_pickup_library)

      Honeybadger.notify(
        "Request id #{request.id} attempted to submit a BorrowDirect request to be picked up at "\
        "#{requested_pickup_library} but the only pickup libraries are #{api_pickup_locations.to_sentence}"
      )

      default_pickup_library
    end

    def default_pickup_library
      library_config[app_config.default_pickup_library]
    end

    def library_config
      app_config.libraries
    end

    def app_config
      SULRequests::Application.config
    end
  end
end
