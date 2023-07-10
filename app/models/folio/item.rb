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

  MaterialType = Data.define(:id)
  LoanType = Data.define(:id)

  # Represents an item returned from the /inventory-hierarchy/items-and-holdings Folio API
  # TODO: This wants a "type" attribute, but I don't know how we get the folio version of a holding type.
  #       See https://github.com/sul-dlss/searchworks_traject_indexer/blob/02192452815de3861dcfafb289e1be8e575cb000/lib/traject/config/sirsi_config.rb#L2379
  # NOTE, barcode and callnumber may be nil. see instance_hrid: 'in00000063826'
  class Item
    attr_reader :barcode, :status, :type, :callnumber, :public_note, :effective_location, :material_type, :loan_type

    # rubocop:disable Metrics/ParameterLists
    def initialize(barcode:, status:, type:, callnumber:, public_note:, effective_location:, material_type: nil, loan_type: nil,
                   due_date: nil)
      @barcode = barcode
      @status = status
      @type = type
      @callnumber = callnumber
      @public_note = public_note
      @effective_location = effective_location
      @material_type = material_type || MaterialType.new(id: nil)
      @loan_type = loan_type || LoanType.new(id: nil)
      @due_date = due_date
    end
    # rubocop:enable Metrics/ParameterLists

    def home_location
      effective_location.code
    end

    def current_location
      status_text unless [STATUS_AVAILABLE, STATUS_PAGED].include? status
    end

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
      Time.zone.parse(@due_date).strftime('%m/%d/%Y') if @due_date
    end

    def hold?
      status == STATUS_HOLD
    end

    def paged?
      effective_location.code =~ /SAL-/ || effective_location.code =~ /SAL3/
    end

    def hold_recallable?
      HOLD_RECALL_STATUSES.include?(status)
    end

    # rubocop:disable Metrics/AbcSize
    def self.from_hash(dyn)
      new(barcode: dyn['barcode'],
          status: dyn.dig('status', 'name'),
          type: dyn.dig('materialType', 'name'),
          callnumber: [dyn.dig('effectiveCallNumberComponents', 'callNumber'), dyn['volume'], dyn['enumeration'],
                       dyn['chronology']].filter_map(&:presence).join(' '),
          public_note: dyn.fetch('notes').find { |note| note.dig('itemNoteType', 'name') == 'Public' }&.fetch('note'),
          effective_location: Location.from_hash(dyn.fetch('effectiveLocation')),
          material_type: MaterialType.new(id: dyn.dig('materialType', 'id')),
          loan_type: LoanType.new(id: dyn.fetch('tempooraryLoanTypeId', dyn.fetch('permanentLoanTypeId'))))
    end
    # rubocop:enable Metrics/AbcSize
  end
end
