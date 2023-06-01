# frozen_string_literal: true

module Folio
  CHECKED_OUT = 'Checked out'
  AVAILABLE = 'Available'

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

    # TODO
    def public_note
      'depr'
    end

    def due_date
      raise "To be implemented (probably need to add real time availablity API. It's not in holdings)"
    end

    def hold?
      raise 'how do we know? See Searchworks::HoldingItem'
    end

    def paged?
      raise 'how do we know? See Searchworks::HoldingItem'
    end
  end
end
