# frozen_string_literal: true

##
# Default options for request workflows
module DefaultRequestOptions
  extend ActiveSupport::Concern
  ITEM_LIMITS = {
    'RUMSEYMAP' => 5,
    'SPEC-COLL' => 5,
    'PAGE-SP' => 5
  }.freeze

  def item_limit
    ITEM_LIMITS[origin] || ITEM_LIMITS[origin_location]
  end

  def requires_needed_date?
    false
  end
end
