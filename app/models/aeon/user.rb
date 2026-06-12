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
      Aeon::RequestFinders.new(self.class.aeon_client.requests_for(username:))
    end

    def requests
      @requests ||= all_requests.reject(&:activity?)
    end

    def activities
      @activities ||= self.class.aeon_client.activities_for(username:).sort_by(&:sort_key)
    end

    def activities_with_requests
      request_cache = {}
      activities.each do |activity|
        user_requests = activity.users.flat_map do |user|
          request_cache[user.username] ||= self.class.aeon_client.requests_for(username: user.username)
        end
        activity.assign_requests_from(user_requests)
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
