# frozen_string_literal: true

module Aeon
  # Wraps an Aeon appointment record
  class RequestGrouping
    def self.from_requests(requests)
      requests.group_by(&:coelesce_key).each_value.map do |group|
        new(group)
      end
    end

    attr_reader :requests

    def initialize(requests)
      @requests = requests
    end
  end
end
