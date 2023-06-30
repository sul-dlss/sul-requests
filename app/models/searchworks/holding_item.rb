# frozen_string_literal: true

module Searchworks
  # A model on the Searchworks holding JSON data
  class HoldingItem
    PROCESSING_LOCATIONS = %w[ON-ORDER INPROCESS ENDPROCESS BINDERY].freeze
    MISSING_LOCATIONS = %w[MISSING].freeze

    def initialize(attributes)
      @barcode = attributes.fetch('barcode')
      @callnumber = attributes.fetch('callnumber')
      @type = attributes.fetch('type')
      @current_location_code = attributes.dig('current_location', 'code')
      # I'm pretty sure due_date, public_note, home_location as well as status and it's subproperties:
      # availability_class and status_text are always in the response from Searchworks, but we don't have
      # it in all the factories yet, so we can't use fetch
      @due_date = attributes['due_date']
      @public_note = attributes['public_note']
      @home_location = attributes['home_location']
      @status_class = attributes.dig('status', 'availability_class')
      @status_text = attributes.dig('status', 'status_text')
    end

    attr_reader :barcode, :callnumber, :type, :current_location_code, :status_class, :status_text,
                :public_note, :due_date, :home_location
    attr_accessor :request_status

    def checked_out?
      current_location_code == 'CHECKEDOUT'
    end

    def on_order?
      current_location_code == 'ON-ORDER'
    end

    def hold?
      current_location_code&.ends_with?('-LOAN')
    end

    def paged?
      home_location&.ends_with?('-30')
    end

    def processing?
      # TODO: in Folio 'In process (non-requestable)', 'In process').include?(itemStatus)
      # This may also involve some temporary locations. See:
      #  https://docs.google.com/spreadsheets/d/1TCWHj45Yb7_7kHst0Cg0Wrk9vGcRX86qYeAqhX1lYvA/edit#gid=0
      PROCESSING_LOCATIONS.include?(current_location_code)
    end

    def missing?
      MISSING_LOCATIONS.include?(current_location_code) # TODO: itemStatus == 'Missing' in Folio
    end
  end
end
