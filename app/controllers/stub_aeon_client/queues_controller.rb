# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class QueuesController < StubAeonClient::ApplicationController
    def index
      render json: (StubAeonClient::Queue.all.map do |queue|
        { queue: queue, requestCount: 0 }
      end)
    end
  end
end
