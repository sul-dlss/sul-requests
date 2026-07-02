# frozen_string_literal: true

module Folio
  # Computes format_hsim from a MARC record using the same rules as
  # searchworks_traject_indexer. Returns a deduped array of format strings
  # such as ['Book'], ['Video/Film', 'Video/Film|Blu-ray'], or [] when no
  # rule matches.
  #
  # @example
  #   Folio::Format.compute(marc_record: instance.marc_record)  # => ['Book']
  module Format
    def self.compute(marc_record: nil)
      record = Record.new(marc_record:)
      accumulator = []
      Rules.all.each { |rule| rule.call(record, accumulator, nil) } # rubocop:disable Rails/FindEach
      accumulator.uniq
    end
  end
end
