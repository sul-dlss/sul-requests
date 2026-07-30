# frozen_string_literal: true

module Aeon
  # Wraps Aeon request records
  class RequestGrouping
    include Enumerable

    attr_reader :requests

    delegate :each, to: :requests

    delegate :submitted?, :base_callnumber, :call_number, :date, :item_url, :digital?, :activity?, :saved_for_later?,
             :document_type, :ead_number, :multi_item_selector?, :title, :group_key, :sort_key, :status, to: :first

    def self.from_requests(requests)
      requests.group_by(&:group_key).values.map { |group| new(group) }
    end

    def initialize(requests)
      @requests = requests.is_a?(Aeon::RequestFinders) ? requests : Aeon::RequestFinders.new(requests)
    end

    def dom_id
      return "group_#{first.id}" unless multi_item_selector?

      "group_#{status}_#{title.parameterize}_#{digital? ? 'digital' : 'reading_room'}"
    end

    def appointment_reading_room
      return if digital?

      requests.submitted.first&.reading_room
    end
  end
end
