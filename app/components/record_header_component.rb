# frozen_string_literal: true

# Render page metadata
class RecordHeaderComponent < ViewComponent::Base
  attr_reader :record, :title_classes

  def initialize(record: nil, brief: false, title_classes: ['fs-5'])
    @record = record
    @brief = brief
    @title_classes = Array(title_classes)
  end

  def call_number
    record.base_callnumber.presence
  end

  def brief?
    @brief
  end
end
