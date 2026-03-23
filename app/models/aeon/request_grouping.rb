# frozen_string_literal: true

module Aeon
  # Wraps Aeon request records
  class RequestGrouping
    include Enumerable

    attr_reader :requests

    delegate :each, to: :requests

    delegate :appointment?, :submitted?, :appointment, :base_callnumber, :call_number, :date, :digital?,
             :document_type, :ead_number, :multi_item_selector?, :title, to: :first

    def self.from_requests(requests)
      multi, single = requests.partition(&:multi_item_selector?)
      groups = multi.group_by { |r| [r.title, r.digital?] }.values.map { |group| new(group) }
      groups + single.map { |r| new([r]) }
    end

    def initialize(requests)
      @requests = requests
    end

    def draft_requests
      requests.select(&:draft?)
    end

    def submitted_requests
      requests.select(&:submitted?)
    end

    # For status display, prefer a pending request over a ready one
    # so the group shows as pending if any request is still pending.
    def status_request
      return first unless digital? && requests.any?(&:submitted?)

      requests.find { |r| !r.scan_delivered? } || first
    end

    def reading_room_name
      appointment&.reading_room&.name
    end
  end
end
