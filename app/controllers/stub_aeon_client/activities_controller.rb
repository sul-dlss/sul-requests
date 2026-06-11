# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class ActivitiesController < StubAeonClient::ApplicationController
    def index
      render json: StubAeonClient::Activity.all
    end
  end
end
