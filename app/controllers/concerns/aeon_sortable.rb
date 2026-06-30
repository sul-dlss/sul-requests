# frozen_string_literal: true

# Provides sorting functionality for Aeon request collections
module AeonSortable
  extend ActiveSupport::Concern

  SORT_OPTIONS = {
    'title' => {
      label: 'Sort by title',
      sort: ->(requests) { requests.sort_by { |r| [r.title.to_s, r.sort_key] } }
    },
    'date_modified' => {
      label: 'Sort by date modified',
      sort: ->(requests) { requests.newest_first(&:transaction_date) }
    },
    'appointment_time' => {
      label: 'Sort by appointment time',
      sort: lambda { |requests|
        requests.sort_by { |r| [r.appointment&.start_time || Time.zone.local(9999), r.title.to_s, r.sort_key] }
      },
      only_for_filters: %w[all reading_room]
    }
  }.freeze

  DEFAULT_SORT = 'date_modified'

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
    filter = respond_to?(:current_aeon_filter, true) ? current_aeon_filter : 'all'
    SORT_OPTIONS.select { |_, option| option[:only_for_filters].nil? || option[:only_for_filters].include?(filter) }
  end
end
