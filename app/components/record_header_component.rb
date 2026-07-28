# frozen_string_literal: true

# Render page metadata
class RecordHeaderComponent < ViewComponent::Base
  attr_reader :record, :title_tag, :title_classes

  def initialize(record: nil, brief: false, title_tag: :h2, title_classes: ['h3'], display_callnumber: true)
    @record = record
    @brief = brief
    @title_tag = title_tag
    @title_classes = Array(title_classes)
    @display_callnumber = display_callnumber
  end

  def call_number
    record.base_callnumber.presence
  end

  def display_callnumber?
    @display_callnumber
  end

  def brief?
    @brief
  end
end
