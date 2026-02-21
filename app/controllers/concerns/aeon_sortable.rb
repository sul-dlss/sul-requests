# frozen_string_literal: true

# Provides sorting functionality for Aeon request collections
module AeonSortable
  extend ActiveSupport::Concern

  SORT_OPTIONS = {
    'request_type' => {
      label: 'Sort by request type',
      sort: ->(requests) { requests.sort_by { |r| [r.digital? ? 0 : 1, r.title.to_s, -r.creation_date.to_i] } }
    },
    'title' => {
      label: 'Sort by title',
      sort: ->(requests) { requests.sort_by { |r| [r.title.to_s, -r.creation_date.to_i] } }
    },
    'date_added' => {
      label: 'Sort by date added',
      sort: ->(requests) { requests.sort_by { |r| [-r.creation_date.to_i, r.title.to_s] } }
    },
    'date_modified' => {
      label: 'Sort by date modified',
      sort: ->(requests) { requests.sort_by { |r| [-r.transaction_date.to_i, r.title.to_s] } }
    },
    'appointment_time' => {
      label: 'Sort by appointment time',
      sort: lambda { |requests|
        requests.sort_by { |r| [r.appointment&.start_time || Time.zone.local(9999), r.title.to_s] }
      }
    }
  }.freeze

  DEFAULT_SORT = 'date_added'

  included do
    helper_method :current_aeon_sort
  end

  private

  def sort_aeon_requests(requests)
    SORT_OPTIONS[current_aeon_sort][:sort].call(requests)
  end

  def current_aeon_sort
    SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : DEFAULT_SORT
  end
end
