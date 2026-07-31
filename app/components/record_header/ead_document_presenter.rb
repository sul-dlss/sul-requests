# frozen_string_literal: true

module RecordHeader
  # Adapts an Ead::Document to the RecordHeaderComponent contract.
  class EadDocumentPresenter
    attr_reader :record

    delegate :title, :author, :item_url, :document_type, :date, :extent, to: :record

    def initialize(record)
      @record = record
    end

    def call_number = record.identifier
  end
end
