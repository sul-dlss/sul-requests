# frozen_string_literal: true

module Folio
  # Component for rendering ILL requests
  class IllRequestComponent < ViewComponent::Base
    with_collection_parameter :request

    attr_reader :request, :patron

    def initialize(request:, patron:)
      @request = request
      @patron = patron
      super()
    end

    def type_label
      request.scan_type? ? 'Digitization' : 'Pickup'
    end
  end
end
