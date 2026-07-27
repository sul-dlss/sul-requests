# frozen_string_literal: true

module Folio
  # Component for rendering FOLIO requests
  class RequestComponent < ViewComponent::Base
    attr_reader :request, :patron

    def initialize(request:, patron:, group: false)
      @request = request
      @patron = patron
      @group = group
      super()
    end

    def contact_email
      request.contact_info&.dig(:email)
    end

    def proxy_borrower
      @proxy_borrower ||= patron.proxies.find(request.patron_key) if request.proxy_request?
    end
  end
end
