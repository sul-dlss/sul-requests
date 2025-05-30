# frozen_string_literal: true

##
# See https://github.com/kickstarter/rack-attack/blob/master/docs/example_configuration.md
# for more configuration options

### Throttle Spammy Clients ###

# If any single client IP is making tons of requests, then they're
# probably malicious or a poorly-configured scraper. Either way, they
# don't deserve to hog all of the app server's CPU. Cut them off!
#
# Note: If you're serving assets through rack, those requests may be
# counted by rack-attack and this throttle may be activated too
# quickly. If so, enable the condition to exclude them from tracking.

Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: Settings.throttling.redis_url) if Settings.throttling.redis_url

Rack::Attack.throttle("requests/new", limit: 10, period: 1.minute) do |req|
  route = begin
    Rails.application.routes.recognize_path(req.path) || {}
  rescue StandardError
    {}
  end
  req.ip if (route[:controller] == 'patron_requests' || route[:controller] == 'requests') && route[:action] == 'new'
end

Rack::Attack.throttle("requests/create", limit: 5, period: 1.minute) do |req|
  route = begin
    Rails.application.routes.recognize_path(req.path) || {}
  rescue StandardError
    {}
  end
  req.ip if route[:controller] == 'patron_requests' && route[:action] == 'create'
end

Rack::Attack.throttle("requests/reset_pins", limit: 5, period: 1.minute) do |req|
  route = begin
    Rails.application.routes.recognize_path(req.path) || {}
  rescue StandardError
    {}
  end
  req.ip if route[:controller] == 'reset_pins'
end


# Inform throttled clients about limits and when they will get out of jail
Rack::Attack.throttled_response_retry_after_header = true
Rack::Attack.throttled_responder = lambda do |request|
  match_data = request.env['rack.attack.match_data']
  now = match_data[:epoch_time]

  if match_data[:count] < 15 || (match_data[:count] % 10).zero?
    Honeybadger.notify("Throttling request", context: { ip: request.ip, path: request.path }.merge(match_data))
  end

  headers = {
    'RateLimit-Limit' => match_data[:limit].to_s,
    'RateLimit-Remaining' => '0',
    'RateLimit-Reset' => (now + (match_data[:period] - (now % match_data[:period]))).to_s
  }

  [429, headers, ["Throttled\n"]]
end

# Disable throttling for Stanford-local users
Rack::Attack.safelist_ip("171.64.0.0/14")
Rack::Attack.safelist_ip("10.0.0.0/8")
Rack::Attack.safelist_ip("172.16.0.0/12")
