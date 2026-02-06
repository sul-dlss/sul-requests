# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    attr_reader :aeon_link, :appointment, :appointment_id, :author, :call_number,
                :creation_date, :date, :document_type, :format, :pages,
                :location, :shipping_option, :title, :transaction_date,
                :transaction_number, :transaction_status, :volume

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      new(
        aeon_link: dyn['itemInfo1'],
        appointment: dyn['appointment'] ? Appointment.from_dynamic(dyn['appointment']) : nil,
        appointment_id: dyn['appointmentID'],
        author: dyn['itemAuthor'],
        call_number: dyn['callNumber'],
        creation_date: Time.zone.parse(dyn.fetch('creationDate')),
        date: dyn['itemDate'],
        document_type: dyn['documentType'],
        format: dyn['format'],
        shipping_option: dyn['shippingOption'],
        location: dyn['location'],
        pages: dyn['itemInfo5'],
        title: dyn['itemTitle'],
        transaction_date: Time.zone.parse(dyn.fetch('transactionDate')),
        transaction_number: dyn['transactionNumber'],
        transaction_status: dyn['transactionStatus'],
        volume: dyn['itemVolume']
      )
    end

    def initialize(aeon_link: nil, appointment: nil, appointment_id: nil, # rubocop:disable Metrics/ParameterLists, Metrics/MethodLength
                   author: nil, call_number: nil, creation_date: nil, date: nil,
                   document_type: nil, format: nil, location: nil, pages: nil,
                   shipping_option: nil, title: nil, transaction_date: nil,
                   transaction_number: nil, transaction_status: nil, volume: nil)
      @aeon_link = aeon_link
      @appointment = appointment
      @appointment_id = appointment_id
      @author = author
      @call_number = call_number
      @creation_date = creation_date
      @date = date
      @document_type = document_type
      @format = format
      @location = location
      @pages = pages
      @shipping_option = shipping_option
      @title = title
      @transaction_date = transaction_date
      @transaction_number = transaction_number
      @transaction_status = transaction_status
      @volume = volume
    end

    def appointment?
      appointment_id.present?
    end

    def digitized_request?
      @shipping_option == 'Electronic Delivery'
    end
  end
end
