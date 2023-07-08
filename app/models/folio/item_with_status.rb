# frozen_string_literal: true

module Folio
  # Other statuses that we aren't using include "Unavailable" and "Intellectual item"
  STATUS_CHECKED_OUT = 'Checked out'
  STATUS_ON_ORDER = 'On order'
  STATUS_AVAILABLE = 'Available'
  STATUS_HOLD = 'Awaiting pickup'
  STATUS_MISSING = 'Missing'
  STATUS_IN_PROCESS_NR = 'In process (non-requestable)'
  STATUS_IN_PROCESS = 'In process'
  STATUS_AWAITING_PICKUP = 'Awaiting pickup'
  STATUS_AWAITING_DELIVERY = 'Awaiting delivery'
  STATUS_IN_TRANSIT = 'In transit'
  STATUS_PAGED = 'Paged'
  STATUS_RESTRICTED = 'Restricted'
  STATUS_NONE = ''

  PAGE_LOCATIONS = %w(HILA-SAL3-STACKS
                      HILA-SAL3-STACKS
                      SPEC-SAL3-FELTON
                      SPEC-SAL3-GUNST
                      SPEC-SAL3-MEDIA
                      SPEC-SAL3-MSS
                      SPEC-SAL3-RBC
                      SPEC-SAL3-U-ARCHIVES
                      SPEC-SAL3-U-ARCHIVES).freeze

  # Statuses that FOLIO treats as valid for intiating a hold/recall
  # See: https://github.com/folio-org/mod-circulation/blob/master/src/main/java/org/folio/circulation/domain/RequestTypeItemStatusWhiteList.java#L71-L94
  HOLD_RECALL_STATUSES = [
    STATUS_CHECKED_OUT,
    STATUS_AWAITING_PICKUP,
    STATUS_AWAITING_DELIVERY,
    STATUS_IN_TRANSIT,
    STATUS_MISSING,
    STATUS_PAGED,
    STATUS_ON_ORDER,
    STATUS_IN_PROCESS,
    STATUS_RESTRICTED,
    STATUS_NONE
  ].freeze

  ItemWithStatus = Data.define(:barcode, :status, :request_status, :type, :public_note, :permanent_location, :temporary_location,
                               :callnumber) do
    def checked_out?
      status == STATUS_CHECKED_OUT
    end

    def on_order?
      status == STATUS_ON_ORDER
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

    def hold_recallable?
      HOLD_RECALL_STATUSES.include?(status)
    end
  end
end
