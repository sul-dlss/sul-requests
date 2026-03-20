# frozen_string_literal: true

module Aeon
  # Wraps an Aeon request record
  class Request
    include ActiveModel::Model
    include ActiveModel::Attributes
    include ActiveModel::AttributeMethods
    include ActiveModel::Dirty

    # appointment attributes
    attribute :appointment
    attribute :appointment_id, :integer

    # identifiers
    attribute :call_number
    attribute :ead_number
    attribute :reference_number
    attribute :site

    # request attributes
    attribute :creation_date, :time
    attribute :document_type
    attribute :transaction_number
    attribute :web_request_form

    # queues
    attribute :shipping_option
    attribute :photoduplication_status
    attribute :photoduplication_date, :time
    attribute :transaction_status
    attribute :transaction_date, :time

    # item attributes
    attribute :item_author
    attribute :item_date
    attribute :item_number
    attribute :item_title
    attribute :item_volume
    attribute :item_info1
    attribute :item_info2
    attribute :item_info3
    attribute :item_info4
    attribute :item_info5

    # other attributes
    attribute :format
    attribute :location
    attribute :special_request
    attribute :for_publication, :boolean

    attribute :username

    def self.from_dynamic(dyn)
      data = attribute_names.index_with do |attr|
        their_parameter_information = Aeon::RequestParameterMapper.to_aeon_options(attr)
        next unless their_parameter_information

        v = dyn[their_parameter_information[:key]]
        Aeon::RequestParameterMapper.cast_value(attr, v)
      end

      new(data).tap(&:clear_changes_information)
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

    attr_accessor :status_was

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

    def reading_room
      return @reading_room if defined?(@reading_room)

      @reading_room = Aeon::ReadingRoom.find_by(site: site)
    end

    def multi_item_selector?
      # Assuming multi-item selection for legacy Aeon requests seems a better default.
      web_request_form != 'single'
    end

    def update(attributes)
      assign_attributes(attributes)
      save
    end

    def save
      self.status_was = status

      Aeon::UpdateRequestService.new(self).call.tap do |created_request|
        assign_attributes(created_request.attributes)

        @photoduplication_queue = nil
        @transaction_queue = nil

        changes_applied
      end

      self
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
      @photoduplication_queue ||= Aeon::Queue.find_by(id: photoduplication_status, type: :photoduplication) # rubocop:disable Rails/FindByOrAssignmentMemoization
    end

    def transaction_queue
      @transaction_queue ||= Aeon::Queue.find_by(id: transaction_status) # rubocop:disable Rails/FindByOrAssignmentMemoization
    end
  end
end
