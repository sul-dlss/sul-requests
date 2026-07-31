# frozen_string_literal: true

module RecordHeader
  # Adapts a Folio::Request to the RecordHeaderComponent contract.
  class FolioRequestPresenter
    attr_reader :record

    delegate :title, :author, :item_url, :document_type, :document_formats, :call_number, to: :record

    def initialize(record)
      @record = record
    end

    def date = record.publication_date
    def extent = nil
  end
end
