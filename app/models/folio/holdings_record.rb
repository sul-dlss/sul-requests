# frozen_string_literal: true

module Folio
  # Represents a holdings record in Folio.
  class HoldingsRecord
    attr_reader :id, :call_number, :instance, :items

    def initialize(call_number:, id: nil, instance: nil, bound_with_item: nil, items: [], suppressed_from_discovery: false) # rubocop:disable Metrics/ParameterLists
      @id = id
      @call_number = call_number
      @instance = instance
      @bound_with_item = bound_with_item
      @suppressed_from_discovery = suppressed_from_discovery
      @items = items
    end

    def bound_with_item
      @bound_with_item&.with_bound_with_child_holdings_record(self)
    end

    def suppressed_from_discovery?
      @suppressed_from_discovery
    end

    def self.from_hash(hash)
      new(
        id: hash['id'],
        call_number: hash.fetch('callNumber'),
        instance: (Folio::Instance.from_dynamic(hash.fetch('instance')) if hash['instance']),
        bound_with_item: (Folio::Item.from_hash(hash.fetch('boundWithItem')) if hash['boundWithItem']),
        items: hash.fetch('items', []).map { |item| Folio::Item.from_hash(item.reverse_merge('holdingsRecord' => hash)) },
        suppressed_from_discovery: hash['discoverySuppress']
      )
    end
  end
end
