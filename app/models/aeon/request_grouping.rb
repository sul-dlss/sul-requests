# frozen_string_literal: true

module Aeon
  # Wraps Aeon request records
  class RequestGrouping
    include Enumerable

    attr_reader :requests

    delegate :each, to: :requests

    delegate :shipping_option, :appointment, :call_number, :date, :digital?, :document_type, :ead_number, :title, to: :first

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

    def reading_room_name
      appointment&.reading_room&.name
    end

    def digitization?
      shipping_option == 'Electronic Delivery'
    end
  end
end
