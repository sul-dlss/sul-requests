# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    attr_reader :appointment, :appointment_id, :creation_date,
                :location, :item_metadata, :transaction_date,
                :transaction_number, :transaction_status, :digitized_request

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      new(
        appointment: dyn['appointment'] ? Appointment.from_dynamic(dyn['appointment']) : nil,
        appointment_id: dyn['appointmentID'],
        creation_date: Time.zone.parse(dyn.fetch('creationDate')),
        digitized_request: dyn['shippingOption'] == 'Electronic Delivery',
        location: dyn['xlocation'],
        item_metadata: {
          'title' => dyn['itemTitle'], 'pages' => dyn['itemInfo5'],
          'date' => dyn['itemDate'], 'format' => dyn['format'],
          'document_type' => dyn['documentType'], 'aeon_link' => dyn['itemInfo1'],
          'volume' => dyn['itemVolume'], 'call_number' => dyn['callNumber'],
          'author' => dyn['itemAuthor']
        },
        transaction_date: Time.zone.parse(dyn.fetch('transactionDate')),
        transaction_number: dyn['transactionNumber'],
        transaction_status: dyn['transactionStatus']
      )
    end

    def initialize(appointment: nil, appointment_id: nil, # rubocop:disable Metrics/ParameterLists
                   creation_date: nil, digitized_request: nil, location: nil,
                   item_metadata: nil, transaction_date: nil,
                   transaction_number: nil, transaction_status: nil)
      @appointment = appointment
      @appointment_id = appointment_id
      @creation_date = creation_date
      @digitized_request = digitized_request
      @location = location
      @item_metadata = item_metadata
      @transaction_date = transaction_date
      @transaction_number = transaction_number
      @transaction_status = transaction_status
    end

    def appointment?
      appointment_id.present?
    end
  end
end
