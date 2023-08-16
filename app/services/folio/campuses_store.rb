# frozen_string_literal: true

module Folio
  # A cache of campus data
  class CampusesStore
    def initialize(data_from_cache)
      @data = data_from_cache.map { |lib_data| Folio::Campus.from_dynamic(lib_data) }
    end

    attr_reader :data

    def find_by(id:)
      data.find { |candidate| candidate.id == id }
    end
  end
end
