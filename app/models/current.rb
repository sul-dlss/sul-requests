# frozen_string_literal: true

# Provide a place to store request-specific global state, like the Aeon client, so it can be shared across controllers and models.
class Current < ActiveSupport::CurrentAttributes
  attribute :aeon_client, default: -> { AeonClient.new }
end
