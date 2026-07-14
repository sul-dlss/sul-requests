# frozen_string_literal: true

# Cache data retrieval from Aeon.
class CachingAeonClient
  attr_reader :aeon_client, :cache_lifetime

  delegate_missing_to :aeon_client

  def self.flush_caches(username:)
    Rails.cache.delete("Users/#{username}")
    Rails.cache.delete("Users/#{username}/requests")
    Rails.cache.delete("Users/#{username}/requests/activeOnly")
    Rails.cache.delete("Users/#{username}/appointments")
    Rails.cache.delete("Users/#{username}/appointments/pendingOnly")

    # POSSIBLE TODO: flush cache of users associated through activities?
  end

  def initialize(aeon_client, cache_lifetime: 5.minutes)
    @aeon_client = aeon_client
    @cache_lifetime = cache_lifetime
  end

  def find_user(username:)
    cached_value = Rails.cache.read("Users/#{username}")

    raise AeonClient::NotFoundError, "User #{username} not found" if cached_value == 'MISSING'

    Rails.cache.fetch("Users/#{username}", expires_in: cache_lifetime) do
      super
    end
  rescue AeonClient::NotFoundError => e
    # add an explicit cache entry if the user is missing to avoid repeating requests to Aeon
    Rails.cache.write("Users/#{username}", 'MISSING', expires_in: cache_lifetime)

    raise e
  end

  def create_user(*, **)
    super.tap do |user|
      Rails.cache.write("Users/#{user.username}", user, expires_in: cache_lifetime)
    end
  end

  def activities
    Rails.cache.fetch('aeon/activities', expires_in: cache_lifetime) do
      super
    end
  end

  def requests_for(username:, active_only: false)
    Rails.cache.fetch("Users/#{username}/requests#{'/activeOnly' if active_only}", expires_in: cache_lifetime) do
      super
    end
  end

  def create_request(*, **)
    super.tap do |request|
      expire_requests_cache(request)
    end
  end

  def update_request(*, **)
    super.tap do |request|
      expire_requests_cache(request)
    end
  end

  def update_request_route(*, **)
    super.tap do |request|
      expire_requests_cache(request)
    end
  end

  def appointments_for(username:, context: 'both', pending_only: true)
    return super unless context == 'both'

    Rails.cache.fetch("Users/#{username}/appointments/#{'/pendingOnly' if pending_only}", expires_in: cache_lifetime) do
      super
    end
  end

  def create_appointment(*, **)
    super.tap do |appointment|
      expire_appointments_cache(appointment)
    end
  end

  def cancel_appointment(appointment)
    super.tap do
      expire_appointments_cache(appointment)
    end
  end

  def update_appointment(*, **)
    super.tap do |appointment|
      expire_appointments_cache(appointment)
    end
  end

  private

  def expire_requests_cache(request)
    return unless request

    Rails.cache.delete("Users/#{request.username}/requests")
    Rails.cache.delete("Users/#{request.username}/requests/activeOnly")
  end

  def expire_appointments_cache(appointment)
    return unless appointment

    Rails.cache.delete("Users/#{appointment.username}/appointments")
    Rails.cache.delete("Users/#{appointment.username}/appointments/pendingOnly")
  end
end
