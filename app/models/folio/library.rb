# frozen_string_literal: true

module Folio
  # Model for FOLIO's library data
  class Library
    attr_reader :id, :code

    def self.from_dynamic(dyn)
      new(id: dyn.fetch('id'), code: dyn.fetch('code'), name: dyn['name'])
    end

    def initialize(id:, code:, name: nil)
      @id = id
      @code = code
      @name = name
    end

    def primary_service_points
      @primary_service_points ||= locations.map(&:primary_service_point_id).uniq.map { |id| Folio::Types.service_points.find_by(id:) }
    end

    def name(fallback_value: code)
      @name ||= cached_data&.name || fallback_value
    end

    def to_h
      { id:, code: }
    end

    def locations
      Folio::Types.locations.where(library_id: id)
    end

    private

    def cached_data
      @cached_data ||= Folio::Types.libraries.find_by(id:)
    end
  end
end
