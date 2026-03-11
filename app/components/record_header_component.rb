# frozen_string_literal: true

# Render page metadata card
class RecordHeaderComponent < ViewComponent::Base
  attr_reader :classes

  def initialize(patron_request: nil, classes: 'bg-light rounded-0 mb-4', record: nil)
    @patron_request = patron_request
    @classes = classes
    @record = record
  end

  def record
    return @record if @record.present?
    return @patron_request.ead_doc if @patron_request.ead_doc

    @patron_request.folio_instance
  end

  def link_text
    return 'View in Archival Collections at Stanford' if record.item_url.match?('/archives.stanford.edu/')

    'View in Searchworks' if record.item_url.match?('/searchworks.stanford.edu/')
  end
end
