# frozen_string_literal: true

module Aeon
  # Wraps Aeon request records
  class RequestGrouping
    include Enumerable

    attr_reader :requests

    delegate :each, to: :requests

    delegate :submitted?, :base_callnumber, :call_number, :date, :digital?,
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

    def appointment_reading_room
      return if digital?

      @appointment_reading_room ||= submitted_requests&.first&.reading_room
    end
  end
end
