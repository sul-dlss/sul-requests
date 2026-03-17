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
    record.document_type.upcase_first if record.respond_to?(:document_type) && record.document_type.present?
  end

  def call_number
    return aeon_request_callnumber if record.is_a?(Aeon::Request)

    record.call_number.presence
  end

  def brief?
    @brief
  end

  private

  def aeon_request_callnumber
    return record.ead_number if record.ead_number

    record.call_number unless record.multi_item_selector?
  end
end
