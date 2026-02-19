# frozen_string_literal: true

module Aeon
  # Model for working with Aeon user information
  class NullUser < Aeon::User
    def initialize(username: nil, auth_type: nil)
      super
    end

    def sso_auth?
      auth_type == 'Default'
    end

    def requests
      @requests ||= []
    end

    def appointments
      @appointments ||= []
    end

    def persisted? = false
  end
end
