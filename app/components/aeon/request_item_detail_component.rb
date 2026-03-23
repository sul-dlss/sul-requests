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
      format_info.present?
    end

    def format_info
      return "Pages: #{requested_pages}" if requested_pages.present?
      return "Item: #{volume}" if volume.present? && !ead?
      return "Format: #{format}" if format.present?

      nil
    end
  end
end
