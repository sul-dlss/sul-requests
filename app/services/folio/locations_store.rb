# frozen_string_literal: true

module Folio
  # A cache of location data
  class LocationsStore
    def initialize(data_from_cache)
      @data = data_from_cache.map { |lib_data| Folio::Location.from_hash(lib_data) }
    end

    attr_reader :data

    def all
      data
    end

    def where(library_id:)
      data.select { |candidate| candidate.library_id == library_id }
    end

    # rubocop:disable Metrics/AbcSize
    def find_by(args)
      if args.key?(:code)
        data.find { |candidate| candidate.code == args[:code] }
      elsif args.key?(:id)
        data.find { |candidate| candidate.id == args[:id] }
      elsif args.key?(:primary_service_point_id)
        data.find { |candidate| candidate.primary_service_point_id == args[:primary_service_point_id] }
      else
        raise "unknown argument #{args.inspect}"
      end
    end
    # rubocop:enable Metrics/AbcSize
  end
end
