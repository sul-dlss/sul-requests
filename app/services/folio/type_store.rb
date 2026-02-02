# frozen_string_literal: true

module Folio
  # An interface to type data
  class TypeStore
    attr_reader :klass, :data

    include Enumerable

    def initialize(klass, data_from_cache)
      @klass = klass
      @data = data_from_cache.map { |p| klass.from_dynamic(p) }.freeze
    end

    delegate :each, to: :data

    def all
      data
    end

    def find_by(**)
      where(**).first
    end

    def where(**kwargs) # rubocop:disable Metrics/AbcSize
      return to_enum(:where, **kwargs) unless block_given?

      raise ArgumentError("expected a single argument, got #{kwargs.inspect}") unless kwargs.size == 1

      key = kwargs.keys.first
      raise ArgumentError("Unknown finder attribute #{key.inspect}") unless finder_attributes.include?(key)

      each { |candidate| yield(candidate) if candidate.public_send(key) == kwargs[key] }
    end

    private

    def finder_attributes
      @finder_attributes ||= klass.instance_methods(false)
    end
  end
end
