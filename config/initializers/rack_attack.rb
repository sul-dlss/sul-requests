Rack::Attack.enabled = Rails.env.production?
redis = Redis.new(Settings.cdl.redis.to_h)
Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(redis: redis)

# 1000 checkouts per user per day; this isn't a specified requirement (hence
# the absurd limit), but seemed useful to keep tabs on
Rack::Attack.throttle("excessive-cdl-checkouts", limit: 5000, period: 24.hours) do |request|
  if request.path == '/cdl/checkout' && request.env['REMOTE_USER'].present?
    [
      'cdl-checkout-throttle',
      request.env['REMOTE_USER']
    ].join(':')
  end
end

# 20 checkouts per item per user per day
Rack::Attack.throttle("excessive-cdl-checkouts-per-item", limit: 20, period: 24.hours) do |request|
  if request.path == '/cdl/checkout' && request.env['REMOTE_USER'].present?
    [
      'cdl-checkout-throttle',
      request.env['REMOTE_USER'],
      req.params['id'].to_s.downcase.gsub(/\s+/, "")
    ].join(':')
  end
end
