# frozen_string_literal: true

# Render page metadata
class RecordHeaderComponent < ViewComponent::Base
  def initialize(patron_request: nil, record: nil, brief: false)
    @patron_request = patron_request
    @record = record
    @brief = brief
  end

  def record
    return @record if @record
    return @patron_request.ead_doc if @patron_request&.ead_doc

    @patron_request&.folio_instance
  end

  def document_type
    # TODO: this will contain logic based on Aeon values
    record.document_type.upcase_first if record.document_type.present?
  end

  def call_number
    record.base_callnumber.presence
  end

  def brief?
    @brief
  end
end
