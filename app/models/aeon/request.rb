# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    attr_reader :item_url, :appointment, :appointment_id, :author, :call_number,
                :creation_date, :date, :document_type, :format, :item_number, :pages, :photoduplication_status,
                :publication, :location, :reference_number, :shipping_option, :site,
                :special_request, :start_time, :stop_time, :title, :transaction_date,
                :transaction_number, :transaction_status, :username, :volume
  
    def self.aeon_client
      AeonClient.new
    end

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      photoduplication_date = dyn['photoduplicationDate'].presence
      new(
        item_url: dyn['itemInfo1'],
        appointment: dyn['appointment'] ? Appointment.from_dynamic(dyn['appointment']) : nil,
        appointment_id: dyn['appointmentID'],
        author: dyn['itemAuthor'],
        call_number: dyn['callNumber'],
        creation_date: Time.zone.parse(dyn.fetch('creationDate')),
        date: dyn['itemDate'],
        document_type: dyn['documentType'],
        format: dyn['format'],
        item_number: dyn['itemNumber'],
        shipping_option: dyn['shippingOption'],
        location: dyn['location'],
        pages: dyn['itemInfo5'],
        photoduplication_date: photoduplication_date ? Time.zone.parse(photoduplication_date) : nil,
        photoduplication_status: dyn['photoduplicationStatus'],
        reference_number: dyn['referenceNumber'],
        site: dyn['site'],
        start_time: dyn['startTime'],
        stop_time: dyn['stopTime'],
        title: dyn['itemTitle'],
        transaction_date: Time.zone.parse(dyn.fetch('transactionDate')),
        transaction_number: dyn['transactionNumber'],
        transaction_status: dyn['transactionStatus'],
        volume: dyn['itemVolume'],
        special_request: dyn['specialRequest'],
        publication: dyn['forPublication']
      )
    end

    def initialize(item_url: nil, appointment: nil, appointment_id: nil, # rubocop:disable Metrics/AbcSize, Metrics/ParameterLists, Metrics/MethodLength
                   author: nil, call_number: nil, creation_date: nil, date: nil,
                   document_type: nil, format: nil, item_number: nil, location: nil, pages: nil, photoduplication_status: nil, photoduplication_date: nil,
                   reference_number: nil, shipping_option: nil, start_time: nil, stop_time: nil, title: nil, transaction_date: nil,
                   transaction_number: nil, transaction_status: nil, username: nil, volume: nil, site: nil,
                   special_request: nil, publication: nil)
      @item_url = item_url
      @appointment = appointment
      @appointment_id = appointment_id
      @author = author
      @call_number = call_number
      @creation_date = creation_date
      @date = date
      @document_type = document_type
      @format = format
      @item_number = item_number
      @location = location
      @pages = pages
      @photoduplication_status = photoduplication_status
      @photoduplication_date = photoduplication_date
      @reference_number = reference_number
      @shipping_option = shipping_option
      @start_time = start_time
      @stop_time = stop_time
      @title = title
      @transaction_date = transaction_date
      @transaction_number = transaction_number
      @transaction_status = transaction_status
      @volume = volume
      @site = site
      @special_request = special_request
      @publication = publication
    end

    def appointment?
      appointment_id.present?
    end

    def completed?
      return false unless in_completed_queue?
      return false if within_persist_completed_request_as_submitted_period?

      true
    end

    def scan_delivered?
      digital? && in_completed_queue?
    end

    def cancelled?
      return false if draft?

      photoduplication_queue&.cancelled? || transaction_queue&.cancelled?
    end

    def draft?
      if digital?
        photoduplication_queue&.draft?
      else
        transaction_queue&.draft?
      end
    end

    def submitted?
      !draft? && !cancelled? && !completed?
    end

    def digital?
      shipping_option == 'Electronic Delivery' && photoduplication_status.present?
    end

    def physical?
      !digital?
    end

    def writable?
      cancelled? || appointment.editable?
    end

    def coalesce_key
      reference_number || transaction_number
    end

    private

    def within_persist_completed_request_as_submitted_period?
      return false unless transaction_date
      return false unless digital?

      transaction_date >= Settings.aeon.days_to_persist_completed_digital_requests_as_submitted.days.ago
    end

    def in_completed_queue?
      return false if draft?

      photoduplication_queue&.completed? || transaction_queue&.completed?
    end

    def photoduplication_queue
      @photoduplication_queue ||= self.class.aeon_client.find_queue(id: photoduplication_status, type: :photoduplication)
    end

    def transaction_queue
      @transaction_queue ||= self.class.aeon_client.find_queue(id: transaction_status, type: :transaction)
    end
  end
end
