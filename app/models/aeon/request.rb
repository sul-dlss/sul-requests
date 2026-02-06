# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    attr_reader :aeon_link, :appointment, :appointment_id, :author,
                :call_number, :creation_date, :document_type, :location,
                :title, :transaction_date, :transaction_number, :transaction_status

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      new(
        aeon_link: dyn['itemInfo1'],
        appointment: dyn['appointment'] ? Appointment.from_dynamic(dyn['appointment']) : nil,
        appointment_id: dyn['appointmentID'],
        author: dyn['itemAuthor'],
        call_number: dyn['callNumber'],
        creation_date: Time.zone.parse(dyn.fetch('creationDate')),
        document_type: dyn['documentType'],
        location: dyn['location'],
        title: dyn['itemTitle'],
        transaction_date: Time.zone.parse(dyn.fetch('transactionDate')),
        transaction_number: dyn['transactionNumber'],
        transaction_status: dyn['transactionStatus']
      )
    end

    def initialize(aeon_link: nil, appointment: nil, appointment_id: nil, author: nil, # rubocop:disable Metrics/MethodLength, Metrics/ParameterLists
                   call_number: nil, creation_date: nil, document_type: nil, location: nil,
                   title: nil, transaction_date: nil, transaction_number: nil, transaction_status: nil)
      @aeon_link = aeon_link
      @appointment = appointment
      @appointment_id = appointment_id
      @author = author
      @call_number = call_number
      @creation_date = creation_date
      @document_type = document_type
      @location = location
      @title = title
      @transaction_date = transaction_date
      @transaction_number = transaction_number
      @transaction_status = transaction_status
    end

    def appointment?
      appointment_id.present?
    end
  end
end
