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
      sponsor.proxy_group_checkouts || []
    end

    def requests
      sponsor.proxy_group_requests
    end

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
