# frozen_string_literal: true

# Abstract base class for API responses from e.g. FOLIO or Illiad
class ApiResponse < ApplicationRecord
  belongs_to :patron_request
  belongs_to :patron_request_item, optional: true
  store :request_data, coder: JSON
  store :response_data, coder: JSON

  default_scope { order(created_at: :desc) }

  after_initialize do
    self.patron_request_id ||= patron_request_item&.patron_request_id
    self.item_id ||= patron_request_item&.item_id
  end
end
