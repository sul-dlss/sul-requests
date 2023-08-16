# frozen_string_literal: true

module Folio
  # A cache of service point data
  class ServicePointStore
    def initialize(data_from_cache)
      @data = data_from_cache.map { |p| Folio::ServicePoint.from_dynamic(p) }
    end

    attr_reader :data

    def find_by(args)
      if args.key?(:code)
        data.find { |candidate| candidate.code == args[:code] }
      elsif args.key?(:id)
        data.find { |candidate| candidate.id == args[:id] }
      else
        raise "unknown argument #{args.inspect}"
      end
    end

    def where(args)
      if args.key?(:is_default_for_campus)
        data.select { |candidate| candidate.is_default_for_campus == args[:is_default_for_campus] }
      elsif args.key?(:is_default_pickup)
        data.select { |candidate| candidate.is_default_pickup == args[:is_default_pickup] }
      else
        raise "unknown argument #{args.inspect}"
      end
    end
  end
end
