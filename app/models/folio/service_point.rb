# frozen_string_literal: true

module Folio
  # A place where FOLIO items can be serviced (e.g. a pickup location)
  class ServicePoint
    attr_reader :id, :code, :name

    def initialize(id:, code:, name:)
      @id = id
      @code = code
      @name = name
    end

    def self.from_dynamic(json)
      new(id: json.fetch('id'),
          code: json.fetch('code'),
          name: json.fetch('name'))
    end
  end
end
