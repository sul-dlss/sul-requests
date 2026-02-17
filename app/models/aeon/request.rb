# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    attr_reader :aeon_link, :appointment, :appointment_id, :author, :call_number,
                :creation_date, :date, :document_type, :format, :pages, :photoduplication_status,
                :location, :shipping_option, :start_time, :stop_time, :title, :transaction_date,
                :transaction_number, :transaction_status, :volume, :site

    def self.aeon_client
      AeonClient.new
    end

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
        photoduplication_status: dyn['photoduplicationStatus'],
        photoduplication_date: Time.zone.parse(dyn.fetch('transactionDate')),
        start_time: dyn['startTime'],
        stop_time: dyn['stopTime'],
        title: dyn['itemTitle'],
        transaction_date: Time.zone.parse(dyn.fetch('transactionDate')),
        transaction_number: dyn['transactionNumber'],
        transaction_status: dyn['transactionStatus'],
        volume: dyn['itemVolume'],
        site: dyn['site']
      )
    end

    def initialize(aeon_link: nil, appointment: nil, appointment_id: nil, # rubocop:disable Metrics/AbcSize, Metrics/ParameterLists, Metrics/MethodLength
                   author: nil, call_number: nil, creation_date: nil, date: nil,
                   document_type: nil, format: nil, location: nil, pages: nil, photoduplication_status: nil, photoduplication_date: nil,
                   shipping_option: nil, start_time: nil, stop_time: nil, title: nil, transaction_date: nil,
                   transaction_number: nil, transaction_status: nil, volume: nil, site: nil)
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
      @photoduplication_status = photoduplication_status
      @photoduplication_date = photoduplication_date
      @shipping_option = shipping_option
      @start_time = start_time
      @stop_time = stop_time
      @title = title
      @transaction_date = transaction_date
      @transaction_number = transaction_number
      @transaction_status = transaction_status
      @volume = volume
      @site = site
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

    def destroyable?(user)
      user.aeon.requests.map(&:transaction_number).include?(transaction_number)
    end

    def writable?(user)
      destroyable?(user) && (cancelled? || appointment.editable?)
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
