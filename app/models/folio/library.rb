# frozen_string_literal: true

module Folio
  # Model for FOLIO's library data
  class Library
    attr_reader :id, :code

    def initialize(id:, code:)
      @id = id
      @code = code
    end

    def primary_service_points
      @primary_service_points ||= locations.pluck('primaryServicePoint').uniq.map { |id| Folio::Types.service_points.find_by(id:) }
    end

    private

    def locations
      Folio::Types.locations.values.select do |loc|
        loc['libraryId'] == id
      end
    end
  end
end
