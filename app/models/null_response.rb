# frozen_string_literal: true

# Response class to return when the API connection fails
class NullResponse
  def success?
    false
  end

  def body
    ''
  end
end
