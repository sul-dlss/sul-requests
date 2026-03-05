# frozen_string_literal: true

# Render page metadata card
class RecordHeaderComponent < ViewComponent::Base
  attr_reader :classes

  def initialize(patron_request:, classes: 'bg-light rounded-0')
    @patron_request = patron_request
    @classes = classes
  end

  def record
    return @patron_request.ead_doc if @patron_request.ead_doc

    @patron_request.folio_instance
  end

  def link_text
    return 'View in Archival Collections at Stanford' if record.item_url.match?('/archives.stanford.edu/')

    'View in Searchworks' if record.item_url.match?('/searchworks.stanford.edu/')
  end
end
