# frozen_string_literal: true

module Aeon
  # Request item identifier
  class RequestItemIdentifierComponent < ViewComponent::Base
    attr_reader :classes, :request

    delegate :ead?, :volume, to: :request

    def initialize(request:, classes: 'p-1 bg-fog-light fw-semibold')
      @request = request
      @classes = classes
    end

    def call_number
      @call_number ||= strip_ead_prefix(request.call_number)
    end

    def container
      volume if ead? && volume.present?
    end

    def separator?
      call_number.present? && container.present?
    end

    def render?
      request.multi_item_selector? && (call_number.present? || container.present?)
    end

    private

    def strip_ead_prefix(call_num)
      prefix = request.ead_number
      return call_num unless prefix.present? && call_num&.start_with?(prefix)

      call_num.delete_prefix(prefix)
    end
  end
end
