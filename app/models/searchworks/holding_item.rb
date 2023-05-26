# frozen_string_literal: true

module Searchworks
  # A model on the Searchworks holding JSON data
  class HoldingItem
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

    def hold?
      current_location_code.ends_with?('-LOAN')
    end

    def paged?
      home_location&.ends_with?('-30')
    end
  end
end
