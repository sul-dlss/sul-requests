# frozen_string_literal: true

module Aeon
  # Render request link
  class RequestLinkComponent < ViewComponent::Base
    attr_reader :request

    delegate :item_url, to: :request

    def initialize(request:)
      @request = request
    end

    def render?
      url.present?
    end

    def call
      link_to url, class: 'su-underline' do
        safe_join(['View in SearchWorks', tag.i(class: 'ms-1 bi bi-arrow-up-right')])
      end
    end

    def url
      return unless item_url&.include?('searchworks')

      item_url
    end
  end
end
