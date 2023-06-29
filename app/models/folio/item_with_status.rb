# frozen_string_literal: true

module Folio
  # Other status that we aren't using include "Unavailable", "On order", "In process", "Intellectual item", "In transit"
  STATUS_CHECKED_OUT = 'Checked out'
  STATUS_AVAILABLE = 'Available'
  STATUS_HOLD = 'Awaiting pickup'
  STATUS_MISSING = 'Missing'
  STATUS_IN_PROCESS_NR = 'In process (non-requestable)'
  STATUS_IN_PROCESS = 'In process'

  PAGE_LOCATIONS = %w(HILA-SAL3-STACKS
                      HILA-SAL3-STACKS
                      SPEC-SAL3-FELTON
                      SPEC-SAL3-GUNST
                      SPEC-SAL3-MEDIA
                      SPEC-SAL3-MSS
                      SPEC-SAL3-RBC
                      SPEC-SAL3-U-ARCHIVES
                      SPEC-SAL3-U-ARCHIVES).freeze

  ItemWithStatus = Data.define(:barcode, :status, :request_status, :type, :public_note, :permanent_location, :temporary_location,
                               :callnumber) do
    def checked_out?
      status == STATUS_CHECKED_OUT
    end

    # TODO, is this complete?
    def status_class
      status == STATUS_AVAILABLE ? 'available' : 'unavailable'
    end

    # TODO, we probably need to handle "Page", which is something Symphony had.
    def status_text
      status
    end

    def processing?
      [STATUS_IN_PROCESS, STATUS_IN_PROCESS_NR].include?(status)
    end

    def missing?
      status == STATUS_MISSING
    end

    def due_date
      '2025-01-01' # TODO: To be implemented (probably need to add real time availablity API. It's not in holdings)
    end

    def hold?
      status == STATUS_HOLD
    end

    def paged?
      PAGE_LOCATIONS.include?(permanent_location)
    end
  end
end
