# frozen_string_literal: true

module Aeon
  # This class is responsible for loading the statuses from a local JSON
  # caching them locally. It also provides some convenience methods for
  # accessing the types.
  class Status
    attr_reader :cache_dir

    def self.list
      file = Rails.root.join('config/aeon/statuses.csv')
      CSV.parse(file.read, headers: true).map(&:to_h) if file.exist?
    end

    def self.find_by(id: nil)
      list.find { |h| h['Aeon ID'].to_i == id }
    end
  end
end
