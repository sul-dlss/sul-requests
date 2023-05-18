# frozen_string_literal: true

###
#  Mixin to define commentable behavior in request objects
###
module Commentable
  # Currently used to comment which items you would like if the
  # location you're requesting from is configured as item commentable
  def item_commentable?
    location_rule&.item_commentable &&
      holdings.one? &&
      holdings_object.mhld.present?
  end
end
