# wrapper for working with the library hours api
module LibraryHoursApi
  def self.get(library_slug, location_slug, range = {})
    LibraryHoursApi::Request.new(library_slug, location_slug, range).get
  end

  # HTTP Request wrapper for the library hours service
  class Request
    include ActiveSupport::Benchmarkable

    attr_reader :library, :location, :range

    def initialize(library, location, range = {})
      @library = library
      @location = location
      @range = range
    end

    def get
      @response ||= Response.new(json)
    end

    def json
      JSON.parse(response)
    rescue JSON::ParserError => e
      Rails.logger.warn("JSON::ParseError for #{api_url}")
      Squash::Ruby.notify e
      {}
    end

    def response
      benchmark "GET #{api_url}" do
        Faraday.get(api_url).body
      end
    rescue Faraday::Error::ConnectionFailed => e
      Rails.logger.warn("HTTP GET for #{api_url} failed with: #{e}")
      Squash::Ruby.notify e
      {}.to_json
    end

    def api_url
      [Settings.hours_api, 'libraries', library, 'locations', location, 'hours.json'].join('/') + '?' + range.to_query
    end

    private

    def logger
      Rails.logger
    end
  end

  # Utility methods for parsing the library hours API response
  class Response
    attr_reader :data

    def initialize(data)
      @data = data
    end

    def open?
      open_hours.any?
    end

    def open_hours
      hours.select(&:open?)
    end

    def hours
      return [] unless data.present?
      data['data']['attributes']['hours'].map do |h|
        Hours.new(h)
      end
    end
  end

  # Hours data wrapper
  class Hours
    attr_reader :data

    def initialize(data = {})
      @data = data
    end

    def open?
      data['open']
    end

    def day
      Time.zone.parse(data['opens_at']).to_date
    end
  end
end
