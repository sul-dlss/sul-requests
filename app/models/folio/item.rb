# frozen_string_literal: true

module Folio
  # Represents an item returned from the /inventory-hierarchy/items-and-holdings Folio API
  # TODO: This wants a "type" attribute, but I don't know how we get the folio version of a holding type.
  #       See https://github.com/sul-dlss/searchworks_traject_indexer/blob/02192452815de3861dcfafb289e1be8e575cb000/lib/traject/config/sirsi_config.rb#L2379
  # NOTE, barcode and callnumber may be nil. see instance_hrid: 'in00000063826'
  class Item
    attr_reader :id, :barcode, :status, :type, :callnumber, :public_note, :effective_location, :permanent_location, :temporary_location,
                :material_type, :loan_type, :holdings_record_id, :enumeration

    # Other statuses that we aren't using include "Unavailable" and "Intellectual item"
    STATUS_CHECKED_OUT = 'Checked out'
    STATUS_ON_ORDER = 'On order'
    STATUS_AVAILABLE = 'Available'
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

    # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
    def initialize(barcode:, status:, callnumber:,
                   effective_location:, permanent_location: nil, temporary_location: nil,
                   type: nil, public_note: nil, material_type: nil, loan_type: nil, enumeration: nil,
                   due_date: nil, id: nil, holdings_record_id: nil, suppressed_from_discovery: false)
      @id = id
      @holdings_record_id = holdings_record_id
      @barcode = barcode.presence || id
      @status = status
      @type = type
      @callnumber = callnumber
      @public_note = public_note
      @effective_location = effective_location
      @permanent_location = permanent_location || effective_location
      @temporary_location = temporary_location
      @material_type = material_type
      @loan_type = loan_type
      @enumeration = enumeration
      @due_date = due_date
      @suppressed_from_discovery = suppressed_from_discovery
    end
    # rubocop:enable Metrics/ParameterLists, Metrics/MethodLength

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

    def suppressed_from_discovery?
      @suppressed_from_discovery
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

    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def status_text
      return temporary_location&.discovery_display_name || 'Not requestable' unless requestable?

      if !circulates?
        'In-library use only'
      elsif status == STATUS_AVAILABLE && requestable?
        'Available'
      elsif hold_recallable?
        status
      else
        'Not requestable'
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

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
      status == STATUS_AWAITING_PICKUP
    end

    def paged?
      PAGE_LOCATIONS.include?(effective_location.code)
    end

    def hold_recallable?
      recallable? || holdable?
    end

    def recallable?
      HOLD_RECALL_STATUSES.include?(status) && allowed_request_types.include?('Recall')
    end

    def holdable?
      HOLD_RECALL_STATUSES.include?(status) && allowed_request_types.include?('Hold')
    end

    def pageable?
      PAGEABLE_STATUSES.include?(status) && allowed_request_types.include?('Page')
    end

    def mediateable?
      permanent_location.details['pageMediationGroupKey'].present? || aeon_pageable?
    end

    def aeon_pageable?
      aeon_site.present?
    end

    def requestable?
      hold_recallable? || mediateable? || pageable?
    end

    def best_request_type
      return 'Recall' if recallable?
      return 'Hold' if holdable?

      'Page' if pageable?
    end

    def aeon_site
      permanent_location.details['pageAeonSite']
    end

    def self.call_number(dyn)
      call_number = dyn.dig('effectiveCallNumberComponents', 'callNumber')
      effective_location_code = dyn.dig('effectiveLocation', 'code')

      if effective_location_code&.include?('SHELBYTITLE')
        'Shelved by title'
      elsif effective_location_code&.include?('SCI-SHELBYSERIES')
        'Shelved by Series title'
      else
        call_number
      end
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def self.from_hash(dyn)
      new(id: dyn['id'],
          barcode: dyn['barcode'],
          suppressed_from_discovery: dyn['discoverySuppress'],
          status: dyn.dig('status', 'name'),
          due_date: dyn['dueDate'],
          enumeration: dyn['enumeration'],
          type: dyn.dig('materialType', 'name'),
          callnumber: [call_number(dyn), dyn['volume'], dyn['enumeration'],
                       dyn['chronology']].filter_map(&:presence).join(' '),
          public_note: dyn.fetch('notes').find { |note| note.dig('itemNoteType', 'name') == 'Public' }&.fetch('note'),
          effective_location: (Location.from_hash(dyn.fetch('effectiveLocation')) if dyn['effectiveLocation']),
          # fall back to the holding record's effective Location; we're no longer guaranteed an item-level permanent location.
          permanent_location: (if dyn['permanentLocation']
                                 Location.from_hash(dyn.fetch('permanentLocation'))
                               end) || (Location.from_hash(dyn.dig('holdingsRecord', 'effectiveLocation')) if dyn.dig('holdingsRecord',
                                                                                                                      'effectiveLocation')),
          temporary_location: (Location.from_hash(dyn.fetch('temporaryLocation')) if dyn['temporaryLocation']),
          material_type: MaterialType.new(id: dyn.dig('materialType', 'id'), name: dyn.dig('materialType', 'name')),
          loan_type: LoanType.new(id: dyn.fetch('temporaryLoanTypeId', dyn.fetch('permanentLoanTypeId'))),
          holdings_record_id: dyn.dig('holdingsRecord', 'id'))
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    private

    def availability_class
      if hold_recallable?
        'hold-recall'
      elsif effective_location.details['availabilityClass'] == 'Offsite' && requestable?
        'deliver-from-offsite'
      elsif status == STATUS_AVAILABLE && requestable?
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

    def allowed_request_types
      request_policy&.dig('requestTypes') || []
    end

    def request_policy
      @request_policy ||= Folio::CirculationRules::PolicyService.instance.item_request_policy(self)
    end

    def circ_class
      'noncirc' unless circulates?
    end
  end
end
