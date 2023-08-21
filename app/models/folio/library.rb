# frozen_string_literal: true

module Folio
  # Model for FOLIO's library data
  class Library
    attr_reader :id, :code

    def self.from_dynamic(dyn)
      new(id: dyn.fetch('id'), code: dyn.fetch('code'))
    end

    def initialize(id:, code:)
      @id = id
      @code = code
    end

    def primary_service_points
      @primary_service_points ||= locations.map(&:primary_service_point_id).uniq.map { |id| Folio::Types.service_points.find_by(id:) }
    end

    def to_h
      { id:, code: }
    end

    private

    def locations
      Folio::Types.locations.where(library_id: id)
    end
  end
end
