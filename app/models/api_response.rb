# frozen_string_literal: true

# Abstract base class for API responses from e.g. FOLIO or Illiad
class ApiResponse < ApplicationRecord
  belongs_to :patron_request
  store :data, coder: JSON

  default_scope { order(created_at: :desc) }
end
