# frozen_string_literal: true

module RecordHeader
  # Adapts an Aeon::Request to the RecordHeaderComponent contract.
  class AeonRequestPresenter
    attr_reader :record

    delegate :title, :author, :item_url, :document_type, :date, to: :record

    def initialize(record)
      @record = record
    end

    def call_number = record.base_callnumber
    def extent = nil
  end
end
