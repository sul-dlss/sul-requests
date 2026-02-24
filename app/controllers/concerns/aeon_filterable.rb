# frozen_string_literal: true

# Provides filtering functionality for Aeon request collections
module AeonFilterable
  extend ActiveSupport::Concern

  FILTER_OPTIONS = {
    'all' => {
      label: 'All requests',
      filter: ->(requests) { requests }
    },
    'digitization' => {
      label: 'Digitization',
      filter: ->(requests) { requests.select(&:digital?) }
    },
    'reading_room' => {
      label: 'Reading room use',
      filter: ->(requests) { requests.reject(&:digital?) }
    }
  }.freeze

  DEFAULT_FILTER = 'all'

  included do
    helper_method :current_aeon_filter
  end

  private

  def filter_aeon_requests(requests)
    FILTER_OPTIONS[current_aeon_filter][:filter].call(requests)
  end

  def current_aeon_filter
    FILTER_OPTIONS.key?(params[:filter]) ? params[:filter] : DEFAULT_FILTER
  end
end
