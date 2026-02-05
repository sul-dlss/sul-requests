# frozen_string_literal: true

module Aeon
  # Model for working with Aeon user information
  class User
    def self.find_by(email_address:, sso: true)
      aeon_client.find_sso_user(username: email_address) if sso
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
      self.class.aeon_client.requests_for(username:)
    end
  end
end
