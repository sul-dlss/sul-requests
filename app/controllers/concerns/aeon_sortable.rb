# frozen_string_literal: true

# Provides sorting functionality for Aeon request collections
module AeonSortable
  extend ActiveSupport::Concern

  SORT_OPTIONS = {
    'date_added' => {
      label: 'Date added (newest first)',
      sort: ->(requests) { requests.sort_by { |r| [-r.creation_date.to_i, r.title.to_s] } }
    },
    'date_modified' => {
      label: 'Date modified (newest first)',
      sort: ->(requests) { requests.sort_by { |r| [-r.transaction_date.to_i, r.title.to_s] } }
    },
    'title' => {
      label: 'Title',
      sort: ->(requests) { requests.sort_by { |r| [r.title.to_s, -r.creation_date.to_i] } }
    },
    'request_type' => {
      label: 'Request type',
      sort: ->(requests) { requests.sort_by { |r| [r.digital? ? 0 : 1, r.title.to_s, -r.creation_date.to_i] } }
    },
    'appointment_time' => {
      label: 'Appointment time (newest first)',
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
    sort_key = SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : DEFAULT_SORT
    SORT_OPTIONS[sort_key][:sort].call(requests)
  end

  def current_aeon_sort
    SORT_OPTIONS.key?(params[:sort]) ? params[:sort] : DEFAULT_SORT
  end
end
