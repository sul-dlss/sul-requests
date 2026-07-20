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

  included do
    helper_method :current_aeon_sort, :available_aeon_sort_options
  end

  private

  def sort_aeon_requests(requests)
    SORT_OPTIONS[current_aeon_sort][:sort].call(requests)
  end

  def default_sort
    case params[:kind]
    when 'submitted'
      'request_timing'
    when 'saved_for_later'
      'title'
    else
      'date'
    end
  end

  def current_aeon_sort
    available_aeon_sort_options.key?(params[:sort]) ? params[:sort] : default_sort
  end

  def sort_option_keys
    return %w[title date request_timing] if default_sort == 'request_timing'

    %w[title date]
  end

  def available_aeon_sort_options
    SORT_OPTIONS.slice(*sort_option_keys)
  end
end
