# frozen_string_literal: true

module Aeon
  # Render request card
  class RequestComponent < ViewComponent::Base
    attr_reader :request

    delegate :aeon_link, :pages, :volume, :format, :title, :date, :document_type, :call_number,
             :transaction_status, :transaction_date, :transaction_number, to: :request

    def initialize(request:)
      @request = request
    end

    def searchworks_link
      return unless aeon_link.include?('searchworks')

      aeon_link
    end

    def format_info
      return "Pages: #{pages}" if pages
      return "Item: #{volume}" if volume
      return "Format: #{format}" if format

      nil
    end

    def status_text
      status = Aeon::Status.find_by(id: transaction_status)
      status['Web Display Name'] || status['Name']
    end
  end
end
