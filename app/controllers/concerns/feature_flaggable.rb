# frozen_string_literal: true

# Mixin for controllers that work with feature flags
module FeatureFlaggable
  extend ActiveSupport::Concern

  COOKIE_KEY = :feature_flags

  def request_feature_flags
    @request_feature_flags ||= cookies[COOKIE_KEY].to_s.split(',').map(&:strip)
  end

  included do
    helper_method :request_feature_flags
  end
end
