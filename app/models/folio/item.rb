# frozen_string_literal: true

module Folio
  # Represents an item returned from the /inventory-hierarchy/items-and-holdings Folio API
  # TODO: This wants a "type" attribute, but I don't know how we get the folio version of a holding type.
  #       See https://github.com/sul-dlss/searchworks_traject_indexer/blob/02192452815de3861dcfafb289e1be8e575cb000/lib/traject/config/sirsi_config.rb#L2379
  # NOTE, barcode and callnumber may be nil. see instance_hrid: 'in00000063826'
  class Item
    attr_reader :barcode, :status, :type, :callnumber, :public_note, :effective_location, :permanent_location, :material_type,
                :loan_type

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

    # Statuses that FOLIO treats as valid for initiating a hold/recall
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

    PAGEABLE_STATUSES = [
      STATUS_AVAILABLE,
      STATUS_RESTRICTED
    ].freeze

    # rubocop:disable Metrics/ParameterLists
    def initialize(barcode:, status:, type:, callnumber:, public_note:,
                   effective_location:, permanent_location: nil, material_type: nil, loan_type: nil,
                   due_date: nil)
      @barcode = barcode
      @status = status
      @type = type
      @callnumber = callnumber
      @public_note = public_note
      @effective_location = effective_location
      @permanent_location = permanent_location || effective_location
      @material_type = material_type
      @loan_type = loan_type
      @due_date = due_date
    end
    # rubocop:enable Metrics/ParameterLists

    def with_status(status)
      Folio::ItemWithStatus.new(self).with_status(status)
    end

    # TODO: rename this to 'permanent_location_code' after migration
    def home_location
      permanent_location.code
    end

    def current_location
      if [STATUS_AVAILABLE, STATUS_PAGED].exclude?(status)
        status_text
      elsif permanent_location.code != effective_location&.code
        effective_location&.code
      end
    end

    def checked_out?
      status == STATUS_CHECKED_OUT
    end

    def on_order?
      status == STATUS_ON_ORDER
    end

    def status_class
      [availability_class, circ_class].compact.join(' ')
    end

    def status_text
      if !circulates?
        'In-library use'
      elsif status == STATUS_AVAILABLE
        'Available'
      else
        'Unavailable'
      end
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
      PAGE_LOCATIONS.include?(effective_location.code)
    end

    def hold_recallable?
      HOLD_RECALL_STATUSES.include?(status)
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def self.from_hash(dyn)
      new(barcode: dyn['barcode'],
          status: dyn.dig('status', 'name'),
          due_date: dyn['dueDate'],
          type: dyn.dig('materialType', 'name'),
          callnumber: [dyn.dig('effectiveCallNumberComponents', 'callNumber'), dyn['volume'], dyn['enumeration'],
                       dyn['chronology']].filter_map(&:presence).join(' '),
          public_note: dyn.fetch('notes').find { |note| note.dig('itemNoteType', 'name') == 'Public' }&.fetch('note'),
          effective_location: Location.from_hash(dyn.fetch('effectiveLocation')),
          # fall back to the holding record's effective Location; we're no longer guaranteed an item-level permanent location.
          permanent_location: (if dyn['permanentLocation']
                                 Location.from_hash(dyn.fetch('permanentLocation'))
                               end) || (Location.from_hash(dyn.dig('holdingsRecord', 'effectiveLocation')) if dyn.dig('holdingsRecord',
                                                                                                                      'effectiveLocation')),
          material_type: MaterialType.new(id: dyn.dig('materialType', 'id'), name: dyn.dig('materialType', 'name')),
          loan_type: LoanType.new(id: dyn.fetch('tempooraryLoanTypeId', dyn.fetch('permanentLoanTypeId'))))
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

    private

    def availability_class
      if effective_location.details['availabilityClass'] == 'Offsite'
        'deliver-from-offsite'
      elsif status == STATUS_AVAILABLE
        'available'
      else
        'unavailable'
      end
    end

    def circulates?
      loan_policy&.fetch('loanable', false)
    end

    def loan_policy
      @loan_policy ||= Folio::CirculationRules::PolicyService.instance.item_loan_policy(self)
    end

    def circ_class
      'noncirc' unless circulates?
    end
  end
end
