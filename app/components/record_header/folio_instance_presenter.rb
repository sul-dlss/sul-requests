# frozen_string_literal: true

module RecordHeader
  # Adapts a Folio::Instance to the RecordHeaderComponent contract.
  class FolioInstancePresenter
    attr_reader :record

    delegate :title, :author, :item_url, :document_type, :document_formats, :call_number, to: :record

    def initialize(record)
      @record = record
    end

    def date = record.pub_date
    def extent = nil
  end
end
