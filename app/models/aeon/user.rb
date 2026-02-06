# frozen_string_literal: true

module Aeon
  # Model for working with Aeon user information
  class User
    attr_reader :username

    def self.find_by(email_address:, sso: true)
      aeon_user = aeon_client.find_user(username: email_address)

      aeon_user if sso && aeon_user.sso_auth?
    end

    def self.aeon_client
      AeonClient.new
    end

    def self.from_dynamic(dyn)
      new(username: dyn['username'], auth_type: dyn['authType'])
    end

    def initialize(username:, auth_type:)
      @username = username
      @auth_type = auth_type
    end

    def sso_auth?
      @auth_type == 'Default'
    end

    def appointments
      self.class.aeon_client.appointments_for(username:)
    end

    def requests
      self.class.aeon_client.requests_for(username:)
    end
  end
end
