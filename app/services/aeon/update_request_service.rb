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
      if @aeon_request.persisted?
        aeon_client.update_request(@aeon_request.transaction_number, as_patch_json)
      else
        aeon_client.create_request(aeon_create_payload)
      end
    end

    def aeon_create_payload
      @aeon_request.attributes.compact.each_with_object({}) do |(k, v), payload|
        their_name = Aeon::RequestParameterMapper.to_aeon_options(k)

        payload[their_name[:key]] = Aeon::RequestParameterMapper.transform_value(k, v) if v
      end
    end

    def as_patch_json
      @aeon_request.changes.map do |k, (_old, new)|
        their_name = Aeon::RequestParameterMapper.to_aeon_options(k)

        if new.nil?
          { op: 'remove', path: "/#{their_name[:key]}" }
        else
          { op: 'replace', path: "/#{their_name[:key]}", value: Aeon::RequestParameterMapper.transform_value(k, new) }
        end
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
