# frozen_string_literal: true

module Folio
  CHECKED_OUT = 'Checked out'
  AVAILABLE = 'Available'
  HOLD = 'Awaiting pickup'
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
      status == CHECKED_OUT
    end

    # TODO, is this complete?
    def status_class
      status == AVAILABLE ? 'available' : 'unavailable'
    end

    # TODO, we probably need to handle "Page", which is something Symphony had.
    def status_text
      status
    end

    # TODO, HUH?
    def current_location_code
      'derp'
    end

    def due_date
      raise "To be implemented (probably need to add real time availablity API. It's not in holdings)"
    end

    def hold?
      status == HOLD
    end

    def paged?
      PAGE_LOCATIONS.include?(permanent_location)
    end
  end
end
