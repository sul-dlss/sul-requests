# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def author
      data['itemAuthor']
    end

    def call_number
      data['callNumber']
    end

    def creation_date
      Time.zone.parse(data['creationDate']) if data['creationDate']
    end

    def document_type
      data['documentType']
    end

    def location
      data['location']
    end

    def title
      data['itemTitle']
    end

    def transaction_date
      Time.zone.parse(data['transactionDate']) if data['transactionDate']
    end

    def transaction_number
      data['transactionNumber']
    end

    def transaction_status
      data['transactionStatus']
    end
  end
end
