# frozen_string_literal: true

module Aeon
  # Request item details
  class RequestItemDetailComponent < ViewComponent::Base
    attr_reader :request

    delegate :pages, :volume, :format, to: :request

    def initialize(request:, variant: :full)
      @request = request
      @variant = variant
    end

    def render?
      format_info.present?
    end

    def format_info
      return "Pages: #{pages}" if pages.present?
      return "Item: #{volume}" if volume.present?
      return "Format: #{format}" if format.present?

      nil
    end
  end
end
