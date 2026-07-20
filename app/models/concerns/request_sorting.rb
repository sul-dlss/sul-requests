# frozen_string_literal: true

# Helpers for sorting different types of requests
module RequestSorting
  def reverse_sort(str)
    return if str.blank?

    str.tr('0123456789', '9876543210')
  end
end
