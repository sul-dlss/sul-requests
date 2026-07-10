# frozen_string_literal: true

module Aeon
  # Model for working with Aeon user information
  class User
    def self.find_by(email_address:)
      aeon_client.find_user(username: email_address)
    end

    def self.aeon_client
      Current.aeon_client
    end

    def self.from_dynamic(data)
      new(username: data['username'], auth_type: data['authType'])
    end

    attr_reader :username, :auth_type

    def initialize(username:, auth_type: nil)
      @username = username
      @auth_type = auth_type
    end

    def ==(other)
      other.is_a?(Aeon::User) && username == other.username
    end
    alias eql? ==

    delegate :hash, to: :username

    def sso_auth?
      auth_type == 'Default'
    end

    def own_requests
      @own_requests ||= Aeon::RequestFinders.new(self.class.aeon_client.requests_for(username:))
    end

    # All requests this user can see: own records plus submitted requests
    # from shared activities (which may be owned by other activity members).
    def own_and_activity_requests
      @own_and_activity_requests ||= Aeon::RequestFinders.new(
        (own_requests.to_a + activities.flat_map { |a| a.requests.to_a }).uniq(&:id)
      )
    end

    def requests
      @requests ||= own_requests.reject(&:activity?)
    end

    def activities
      @activities ||= begin
        activities = Aeon::Activity.where(username:).sort_by(&:sort_key)
        # use the same user instances across activities to preserve e.g. memoized requests
        users_cache = activities.flat_map(&:users).index_by(&:username).merge(username => self)

        activities.each do |activity|
          users = users_cache.values_at(*activity.users.map(&:username)).compact
          activity.users = users
        end

        Aeon::ActivityFinders.new(activities)
      end
    end

    def appointments
      @appointments ||= begin
        appointments = self.class.aeon_client.appointments_for(username:)

        # augment appointments with their requests
        appointments.each do |appointment|
          appointment.user = self
        end

        Aeon::AppointmentFinders.new(appointments.sort_by(&:sort_key).reject(&:cancelled?))
      end
    end

    def persisted? = true
  end
end
