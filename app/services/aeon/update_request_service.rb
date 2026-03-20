# frozen_string_literal: true

module Aeon
  # Update an existing Aeon request with new data and update the current request route if needed.
  class UpdateRequestService
    attr_reader :aeon_request, :params, :aeon_client

    def initialize(aeon_request, params, aeon_client: AeonClient.new)
      @aeon_request = aeon_request
      @params = params
      @aeon_client = aeon_client
    end

    def call
      @aeon_request = update_request
      @aeon_request = update_request_route

      @aeon_request
    end

    private

    def update_request
      aeon_client.update_request(
        @aeon_request.transaction_number,
        AeonClient::RequestData.with_defaults.with(
          appointment_id: params[:appointment_id]&.to_i,
          for_publication: ActiveRecord::Type::Boolean.new.cast(params[:for_publication]),
          item_info5: params[:requested_pages],
          special_request: params[:additional_information]
        )
      )
    end

    def needs_set_to_submitted?
      aeon_request.draft? && aeon_request.valid?
    end

    def needs_set_to_draft?
      aeon_request.submitted? && !aeon_request.valid?
    end

    def update_request_route # rubocop:disable Metrics/AbcSize
      new_status = if params[:status]
                     params[:status]
                   elsif needs_set_to_submitted?
                     'Awaiting Request Processing'
                   elsif needs_set_to_draft?
                     Settings.aeon.queue_names.draft.transaction.first
                   end

      return aeon_request unless new_status

      aeon_client.update_request_route(transaction_number: aeon_request.transaction_number,
                                       status: params[:status])
    end
  end
end
