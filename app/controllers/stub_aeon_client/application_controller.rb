# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class ApplicationController < ActionController::Base
    skip_forgery_protection
  end
end
