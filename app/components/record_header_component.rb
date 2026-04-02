# frozen_string_literal: true

# Render page metadata
class RecordHeaderComponent < ViewComponent::Base
  def initialize(record: nil, brief: false)
    @record = record
    @brief = brief
  end

  attr_reader :record

  def document_type
    # TODO: this will contain logic based on Aeon values
    record.document_type.presence&.upcase_first
  end

  def call_number
    record.base_callnumber.presence
  end

  def brief?
    @brief
  end
end
