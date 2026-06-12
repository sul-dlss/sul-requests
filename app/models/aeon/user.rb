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

    def all_requests
      @all_requests ||= Aeon::RequestFinders.new(self.class.aeon_client.requests_for(username:))
    end

    def requests
      @requests ||= all_requests.reject(&:activity?)
    end

    def activities
      @activities ||= self.class.aeon_client.activities_for(username:).sort_by(&:sort_key)
    end

    def activities_with_requests # rubocop:disable Metrics/AbcSize
      users_cache = activities.flat_map(&:users).index_by(&:username)

      activities.each do |activity|
        users = users_cache.values_at(*activity.users.map(&:username)).compact
        activity_requests = users.flat_map { |u| u.all_requests.for_activity(activity).submitted }

        activity.requests = Aeon::RequestFinders.new(activity_requests)
      end
      activities
    end

    def active_reading_room_activities(site:)
      activities&.select(&:active?)&.select { |activity| activity.sites.include?(site) }
    end

    def appointments
      @appointments ||= self.class.aeon_client.appointments_for(username:).sort_by(&:sort_key).reject(&:cancelled?).each do |appointment|
        appointment.requests = requests.for_appointment(appointment)
      end
    end

    def appointment_by_id(id:)
      appointments.find { |appointment| appointment.id == id.to_i }
    end

    def appointments_for(site:)
      appointments.select { |appt| appt.reading_room.sites.include?(site) }
    end

    def persisted? = true
  end
end
