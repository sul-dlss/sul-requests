# frozen_string_literal: true

module Aeon
  # Model for working with Aeon user information
  class User
    def self.find_by(email_address:)
      aeon_client.find_user(username: email_address)
    end

    def self.aeon_client
      AeonClient.new
    end

    attr_reader :user_info

    def initialize(fields = {})
      @user_info = fields
    end

    def username
      user_info['username']
    end

    def auth_type
      user_info['authType']
    end

    def sso_auth?
      auth_type == 'Default'
    end

    def requests
      @requests ||= self.class.aeon_client.requests_for(username:)
    end

    def draft_requests
      requests.select(&:draft?)
    end

    def submitted_requests
      requests.select(&:submitted?)
    end

    def cancelled_requests
      requests.select(&:cancelled?)
    end

    def appointments
      @appointments ||= self.class.aeon_client.appointments_for(username:).sort_by(&:sort_key).each do |appointment|
        appointment.requests = requests.select { |request| !request.cancelled? && request.appointment_id == appointment.id }
      end
    end
  end
end
