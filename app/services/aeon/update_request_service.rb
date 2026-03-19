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
    end

    private

    def update_request
      aeon_client.update_request(
        @aeon_request.transaction_number,
        AeonClient::RequestData.with_defaults.with(
          appointment_id: params[:appointment_id]&.to_i,
          for_publication: params[:for_publication] == 'yes',
          item_info5: params[:requested_pages],
          special_request: params[:additional_information]
        )
      )
    end
  end
end
