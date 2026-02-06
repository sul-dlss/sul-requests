# frozen_string_literal: true

module Aeon
  # This class is responsible for loading the statuses from a local JSON
  # caching them locally. It also provides some convenience methods for
  # accessing the types.
  class Status
    attr_reader :cache_dir

    def self.list
      file = Rails.root.join('config/aeon/status.json')
      JSON.parse(file.read) if file.exist?
    end

    def self.find_by(id: nil)
      list['transactionStatuses'].find { |h| h['id'] == id }['name']
    end
  end
end
