# frozen_string_literal: true

module Folio
  # Wraps Folio request records
  class RequestGrouping
    extend ActiveModel::Naming
    include ActiveModel::Conversion
    include Enumerable

    attr_reader :requests

    delegate :each, to: :requests

    delegate :call_number, :catkey, :sort_key, :title,
             :document_type, :full_call_number, :author,
             :identifiers, :vol_enum_chron,
             to: :first

    def self.from_requests(requests)
      requests.group_by(&:catkey).values.map { |group| new(group) }
    end

    def initialize(requests)
      @requests = requests.sort_by(&:full_call_number)
    end

    def to_key
      [catkey]
    end
  end
end
