# frozen_string_literal: true

module Aeon
  # Render digitized request card
  class DigitizedRequestComponent < ViewComponent::Base
    attr_reader :request

    delegate :item_metadata, :transaction_status, :transaction_date, :transaction_number, to: :request

    def initialize(request:)
      @request = request
    end

    def searchworks_link
      return unless item_metadata['aeon_link'].include?('searchworks')

      item_metadata['aeon_link']
    end

    def format_info
      return "Pages: #{item_metadata['pages']}" if item_metadata['pages']
      return "Item: #{item_metadata['volume']}" if item_metadata['volume']
      return "Format: #{item_metadata['format']}" if item_metadata['format']

      nil
    end

    def status_text
      Aeon::Status.find_by(id: transaction_status)
    end
  end
end
