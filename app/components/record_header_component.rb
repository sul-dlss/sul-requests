# frozen_string_literal: true

# Render page metadata in a card wrapper
class RecordHeaderComponent < ViewComponent::Base
  attr_reader :record, :classes, :title_tag, :title_classes

  renders_one :cover_image

  def initialize(record: nil, classes: 'bg-light rounded-0 mb-4', title_tag: :h2, title_classes: ['h3'])
    @record = record
    @classes = classes
    @title_tag = title_tag
    @title_classes = Array(title_classes)
  end

  def call_number
    record.base_callnumber.presence
  end
end
