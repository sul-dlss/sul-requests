# LibraryHours is responsbile for determining
# if a library is open on a given day
class LibraryHours
  def initialize(library_code)
    @library = library_code
  end

  def next_business_day(date = Time.zone.today)
    return nil unless days.keys.include?(date)
    return date if business_days.include?(date)
    date += 1.day until business_days.include?(date)
    date
  end

  def business_days
    @business_days ||= days.map do |date, open|
      date if open
    end.compact
  end

  def library
    config.scanning_library_proxy[@library] || @library
  end

  private

  def days
    @days ||= day_data.each_with_object({}) do |day, hash|
      hash[Date.parse(day['opens_at'])] = day['open']
    end
  end

  def day_data
    return [] unless json.present?
    json['data']['attributes']['hours']
  end

  def response
    @response ||= begin
      Faraday.get(api_url)
    rescue Faraday::Error::ConnectionFailed => e
      Rails.logger.warn("HTTP GET for #{api_url} failed with: #{e}")
      NullResponse.new
    end
  end

  def json
    return {} unless response.success?
    @json ||= begin
      JSON.parse(response.body)
    rescue JSON::ParserError
      Rails.logger.warn("JSON::ParseError for #{api_url}")
      {}
    end
  end

  def api_url
    [Settings.hours_api, 'libraries', library_slug, 'locations', location_slug, 'hours.json'].join('/') + date_range
  end

  def date_range
    "?from=#{Time.zone.today}&to=#{Time.zone.today + 2.months}"
  end

  def library_slug
    location_map[:library_slug]
  end

  def location_slug
    location_map[:location_slug]
  end

  def location_map
    config.hours_api_location_map[library]
  end

  def config
    SULRequests::Application.config
  end
end
