# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    include ActiveModel::Model

    # appointment attributes
    attr_accessor :appointment, :appointment_id

    # identifiers
    attr_accessor :call_number, :ead_number, :reference_number, :site

    # request attributes
    attr_accessor :creation_date, :document_type, :transaction_number, :web_request_form

    # queues
    attr_accessor :shipping_option, :photoduplication_status, :photoduplication_date, :transaction_status, :transaction_date

    # item attributes
    attr_accessor :item_author, :item_date, :item_number, :item_title, :item_volume,
                  :item_info1, :item_info2, :item_info3, :item_info4, :item_info5

    # other attributes
    attr_accessor :format, :location, :special_request, :username

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      photoduplication_date = dyn['photoduplicationDate'].presence
      new(
        appointment: dyn['appointment'] ? Appointment.from_dynamic(dyn['appointment']) : nil,
        appointment_id: dyn['appointmentID'],
        call_number: dyn['callNumber'],
        creation_date: Time.zone.parse(dyn.fetch('creationDate')),
        document_type: dyn['documentType'],
        ead_number: dyn['eadNumber'],
        format: dyn['format'].presence,
        for_publication: dyn['forPublication'],
        item_author: dyn['itemAuthor'],
        item_date: dyn['itemDate'],
        item_info1: dyn['itemInfo1'],
        item_info4: dyn['itemInfo4'],
        item_info5: dyn['itemInfo5'],
        item_number: dyn['itemNumber'],
        item_title: dyn['itemTitle'],
        item_volume: dyn['itemVolume'].presence,
        location: dyn['location'],
        photoduplication_date: photoduplication_date ? Time.zone.parse(photoduplication_date) : nil,
        photoduplication_status: dyn['photoduplicationStatus'],
        reference_number: dyn['referenceNumber'],
        shipping_option: dyn['shippingOption'],
        site: dyn['site'],
        special_request: dyn['specialRequest'].presence,
        transaction_date: Time.zone.parse(dyn.fetch('transactionDate')),
        transaction_number: dyn['transactionNumber'],
        transaction_status: dyn['transactionStatus'],
        username: dyn['username'],
        web_request_form: dyn['webRequestForm']
      )
    end

    alias_attribute :id, :transaction_number
    alias_attribute :item_url, :item_info1
    alias_attribute :access_restrictions, :item_info4
    alias_attribute :pages, :item_info5
    alias_attribute :requested_pages, :item_info5
    alias_attribute :author, :item_author
    alias_attribute :date, :item_date
    alias_attribute :title, :item_title
    alias_attribute :volume, :item_volume
    alias_attribute :publication, :for_publication
    alias_attribute :additional_information, :special_request

    def appointment?
      appointment_id.present?
    end

    def status
      if completed? || scan_delivered?
        :completed
      elsif cancelled?
        :cancelled
      elsif submitted?
        :submitted
      else
        :draft
      end
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
      (digital? && photoduplication_queue&.cancelled?) || transaction_queue&.cancelled?
    end

    def draft?
      transaction_queue.nil? || transaction_queue&.draft?
    end

    def valid?
      if digital?
        requested_pages.present?
      else
        appointment_id.present?
      end
    end

    def submitted?
      !draft? && !cancelled? && !completed?
    end

    def digital?
      shipping_option == 'Electronic Delivery'
    end

    def ead?
      # Legacy requests don't have ead_number set
      ead_number.present? || ['oac.cdlib.org', 'archives.stanford.edu'].any? { |s| item_url.include?(s) }
    end

    def physical?
      !digital?
    end

    def coalesce_key
      reference_number || transaction_number
    end

    def persisted? = id.present?

    def for_publication = @for_publication || false

    def for_publication=(value)
      @for_publication = ActiveModel::Type::Boolean.new.cast(value)
    end

    def reading_room
      return @reading_room if defined?(@reading_room)

      @reading_room = Aeon::ReadingRoom.find_by(site: site)
    end

    def multi_item_selector?
      # Assuming multi-item selection for legacy Aeon requests seems a better default.
      @web_request_form != 'single'
    end

    private

    def within_persist_completed_request_as_submitted_period?
      return false unless transaction_date
      return false unless digital?

      transaction_date >= Settings.aeon.days_to_persist_completed_digital_requests_as_submitted.days.ago
    end

    def in_completed_queue?
      return false if draft?

      (digital? && photoduplication_queue&.completed?) || transaction_queue&.completed?
    end

    def photoduplication_queue
      return @photoduplication_queue if defined?(@photoduplication_queue)

      @photoduplication_queue = Aeon::Queue.find_by(id: photoduplication_status, type: :photoduplication)
    end

    def transaction_queue
      return @transaction_queue if defined?(@transaction_queue)

      @transaction_queue = Aeon::Queue.find_by(id: transaction_status)
    end
  end
end
