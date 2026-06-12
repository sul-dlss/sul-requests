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
      @requests ||= all_requests
    end

    def all_requests
      Aeon::RequestFinders.new([])
    end

    def appointments
      @appointments ||= []
    end

    def present? = false

    def persisted? = false
  end
end
