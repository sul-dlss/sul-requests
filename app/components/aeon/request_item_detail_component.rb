# frozen_string_literal: true

module Aeon
  # Request item details
  class RequestItemDetailComponent < ViewComponent::Base
    attr_reader :request

    delegate :ead?, :requested_pages, :volume, :format, to: :request

    def initialize(request:, variant: :full)
      @request = request
      @variant = variant
    end

    def render?
      value.present?
    end

    def label
      if requested_pages.present?
        'Instructions'
      elsif volume.present? && !ead?
        'Volume'
      elsif format.present?
        'Format'
      end
    end

    def value
      if requested_pages.present?
        requested_pages
      elsif volume.present? && !ead?
        volume
      elsif format.present?
        format
      end
    end
  end
end
