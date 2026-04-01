# frozen_string_literal: true

# Render page metadata in a card wrapper
class RecordHeaderCardComponent < RecordHeaderComponent
  def initialize(classes: 'bg-light rounded-0 mb-4', record: nil, brief: false)
    @classes = classes
    super(record: record, brief: brief)
  end

  attr_reader :classes

  def call
    tag.div(class: "card border-0 #{classes}") do
      tag.div(class: 'card-body') do
        super
      end
    end
  end
end
