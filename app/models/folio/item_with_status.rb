# frozen_string_literal: true

module Folio
  # Folio::Item extended with the current status of the item in the request.
  class ItemWithStatus < SimpleDelegator
    def with_status(request_status)
      @request_status = request_status
      self
    end

    attr_reader :request_status
  end
end
