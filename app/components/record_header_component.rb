# frozen_string_literal: true

# Render page metadata in a card wrapper.
#
# Records are wrapped in a RecordHeader::*Presenter
class RecordHeaderComponent < ViewComponent::Base
  attr_reader :record, :classes, :title_tag, :title_classes

  renders_one :cover_image

  # Wrap a raw record in the appropriate presenter and build the component.
  def self.for(record, **)
    new(record: presenter_for(record), **)
  end

  def self.presenter_for(record)
    case record
    when Aeon::Request   then RecordHeader::AeonRequestPresenter.new(record)
    when Ead::Document   then RecordHeader::EadDocumentPresenter.new(record)
    when Folio::Request  then RecordHeader::FolioRequestPresenter.new(record)
    when Folio::Instance then RecordHeader::FolioInstancePresenter.new(record)
    else raise ArgumentError, "No RecordHeader presenter for #{record.class}"
    end
  end

  def initialize(record:, classes: 'bg-light rounded-0 mb-4', title_tag: :h2, title_classes: ['h3'])
    @record = record
    @classes = classes
    @title_tag = title_tag
    @title_classes = Array(title_classes)
  end
end
