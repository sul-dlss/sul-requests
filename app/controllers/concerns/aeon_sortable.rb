# frozen_string_literal: true

# Provides sorting functionality for Aeon request collections
module AeonSortable
  extend ActiveSupport::Concern

  SORT_OPTIONS = {
    'title' => {
      label: 'Sort by title',
      sort: ->(requests) { requests.sort_by { |r| r.sort_key(:title) } }
    },
    'date' => {
      label: 'Sort by date modified',
      sort: ->(requests) { requests.sort_by { |r| r.sort_key(:date) } }
    },
    'request_timing' => {
      label: 'Sort by request timing',
      sort: lambda { |requests|
        requests.sort_by { |r| r.sort_key(:default) }
      }
    }
  }.freeze

  DEFAULT_SORT = 'request_timing'

  included do
    helper_method :current_aeon_sort, :available_aeon_sort_options
  end

  private

  def sort_aeon_requests(requests)
    SORT_OPTIONS[current_aeon_sort][:sort].call(requests)
  end

  def current_aeon_sort
    available_aeon_sort_options.key?(params[:sort]) ? params[:sort] : DEFAULT_SORT
  end

  def available_aeon_sort_options
    SORT_OPTIONS
  end
end
