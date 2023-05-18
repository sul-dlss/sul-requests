# frozen_string_literal: true

###
#  Mixin to define commentable behavior in request objects
###
module Commentable
  # Used for adding ad-hoc items that are not listed in the holdings
  def ad_hoc_item_commentable?
    location_rule&.ad_hoc_item_commentable
  end

  # Currently used to comment which items you would like if the
  # location you're requesting from is configured as item commentable
  def item_commentable?
    location_rule&.item_commentable &&
      holdings.one? &&
      holdings_object.mhld.present?
  end
end
