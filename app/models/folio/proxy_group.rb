# frozen_string_literal: true

module Folio
  # Class to model Research group information
  class ProxyGroup
    attr_reader :sponsor, :proxy

    delegate_missing_to :sponsor

    def initialize(sponsor, proxy: nil)
      @sponsor = sponsor
      @proxy = proxy
    end

    def with_proxy(proxy)
      self.class.new(sponsor, proxy:)
    end

    def checkouts
      sponsor.all_checkouts.select(&:proxy_checkout?)
    end

    def requests
      sponsor.folio_requests.select(&:proxy_request?)
    end

    def borrow_direct_requests = []
    def illiad_requests = []

    # NOTE: Fines on items borrowed by a proxy/group are associated
    # with the sponsor's individual account.
    def fines
      []
    end

    def payments
      []
    end

    def members
      proxies
    end
  end
end
