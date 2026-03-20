# frozen_string_literal: true

module Aeon
  # Update an existing Aeon request with new data and update the current request route if needed.
  class UpdateRequestService
    attr_reader :aeon_request, :aeon_client

    def initialize(aeon_request, aeon_client: AeonClient.new)
      @aeon_request = aeon_request
      @aeon_client = aeon_client
    end

    def call
      @aeon_request = update_request
      @aeon_request = update_request_route

      @aeon_request
    end

    private

    def update_request
      aeon_client.update_request(@aeon_request.transaction_number, as_patch_json)
    end

    def as_patch_json
      @aeon_request.changes.map do |k, (_old, new)|
        if new.nil?
          { op: 'remove', path: requests_to_aeon_mapping(k) }
        else
          { op: 'replace', path: requests_to_aeon_mapping(k), value: new }
        end
      end
    end

    def requests_to_aeon_mapping(attribute_key)
      case attribute_key
      when :appointment_id
        '/appointmentID'
      else
        "/#{attribute_key.to_s.camelize(:lower)}"
      end
    end

    def needs_set_to_submitted?
      aeon_request.draft? && aeon_request.valid?
    end

    def needs_set_to_draft?
      aeon_request.submitted? && !aeon_request.valid?
    end

    def update_request_route
      if needs_set_to_submitted?
        aeon_client.update_request_route(transaction_number: aeon_request.transaction_number,
                                         status: 'Awaiting Request Processing')
      elsif needs_set_to_draft?
        aeon_client.update_request_route(transaction_number: aeon_request.transaction_number,
                                         status: Settings.aeon.queue_names.draft.transaction.first)
      else
        aeon_request
      end
    end
  end
end
