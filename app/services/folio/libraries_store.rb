# frozen_string_literal: true

module Folio
  # A cache of library data
  class LibrariesStore
    def initialize(data_from_cache)
      @data = data_from_cache.map { |lib_data| Folio::Library.from_dynamic(lib_data) }
    end

    attr_reader :data

    def all
      data
    end

    def find_by(args)
      if args.key?(:code)
        data.find { |candidate| candidate.code == args[:code] }
      elsif args.key?(:id)
        data.find { |candidate| candidate.id == args[:id] }
      else
        raise "unknown argument #{args.inspect}"
      end
    end
  end
end
