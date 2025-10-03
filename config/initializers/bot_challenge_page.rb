BotChallengePage.configure do |config|

  # If disabled, no challenges will be issued
  config.enabled = Settings.turnstile.enabled

  # Get from CloudFlare Turnstile: https://www.cloudflare.com/application-services/products/turnstile/
  # Some testing keys are also available: https://developers.cloudflare.com/turnstile/troubleshooting/testing/

  config.cf_turnstile_sitekey = Settings.turnstile.site_key
  config.cf_turnstile_secret_key = Settings.turnstile.secret_key

  # For rate-limiting, we need a rails cache store that keeps state, by default
  # will use `config.action_controller.cache_store` or Rails.cache, but if you'd
  # like to use a separate store database, eg. :
  # config.store = ActiveSupport::Cache::RedisCacheStore.new(url: "...")

  # Exempt any IPs contained in the CIDR blocks in Settings.turnstile.safelist.
  # Exempt any user agents in Settings.turnstile.allowed_user_agents (for registered bots/crawlers).
  # Exempt logged-in users.
  config.skip_when = lambda do |_config|
      Settings.turnstile.safelist.map { |cidr| IPAddr.new(cidr) }.any? { |range| request.remote_ip.in?(range) } ||
      Settings.turnstile.allowed_user_agents.any? { |x| request.user_agent.include?(x) } ||
      current_user?
  end

  # Hook after a bot challenge is presented, for logging or other
  # config.after_blocked = ->(bot_challenge_controller) {
  # }


  # How long will a challenge success exempt a session from further challenges?
  # config.session_passed_good_for = 36.hours


  # Functions like to Rails rate_limit `by` parameter, as a configured default.
  # A discriminator or identifier in which a client's requests will be bucketted
  # by rate limit. Normally this gem buckets by IP address subnets. Switching
  # to individual IPs would be much more generous:
  # config.default_limit_by = ->(config) {
  #   request.remote_ip
  #  }

  # When a "pass" cookie is saved, a fingerprint value is stored with it,
  # and subsequent uses of the pass need to have a request that matches
  # fingerprint. By default we insist on IP subnet match, and same user-agent
  # and other headers. But can be customized.
  # config.session_valid_fingerprint = ->(request) {
  #    # whatever
  # }

end
