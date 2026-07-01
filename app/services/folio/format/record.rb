# frozen_string_literal: true

module Folio
  module Format
    # Adapter that lets a MARC::Record act like the FolioRecord object the
    # format rules expect.
    #
    # The rules call:
    #   - leader        (MARC leader string, or nil)
    #   - fields(tag)   (MARC fields matching tag, or [] if no MARC)
    #   - [](tag)       (first MARC field with tag, or nil)
    #   - statistical_codes (FOLIO array of { 'name' => ... }) - stubbed
    #   - holdings          (FOLIO array of holdings hashes)   - stubbed
    class Record
      def initialize(marc_record: nil)
        @marc_record = marc_record
      end

      def leader
        @marc_record&.leader
      end

      def fields(tag = nil)
        return [] unless @marc_record

        tag ? @marc_record.fields(tag) : @marc_record.fields
      end

      def [](tag)
        @marc_record&.[](tag)
      end

      # searchworks_traject_indexer's format uses this only for 'Database', a type Requests does not deal with.
      def statistical_codes
        []
      end

      # searchworks_traject_indexer's format uses this for 'Equipment' and one path for 'Video/Film|Blu-ray'
      def holdings
        []
      end
    end
  end
end
