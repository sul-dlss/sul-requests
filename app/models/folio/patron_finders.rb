# frozen_string_literal: true

module Folio
  # Wraps a group of FOLIO patrons with finder methods
  class PatronFinders
    include Enumerable

    attr_reader :patrons

    delegate :each, :length, to: :patrons

    def initialize(patrons = [])
      @patrons = patrons
    end

    def find(id_or_ids = nil, &)
      return super(&) if block_given?

      if id_or_ids.is_a?(Array)
        ids = id_or_ids
        self.class.new(patrons.select { |patron| ids.include?(patron.id) })
      else
        id = id_or_ids
        patrons.find { |patron| patron.id == id }
      end
    end
  end
end
