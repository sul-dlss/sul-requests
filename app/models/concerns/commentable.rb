# frozen_string_literal: true

###
#  Mixin to define commentable behavior in request objects
###
module Commentable
  # Used for adding ad-hoc items that are not listed in the holdings
  def ad_hoc_item_commentable?
    SULRequests::Application.config.ad_hoc_item_commentable_libraries.include?(origin)
  end

  # Currently used to comment which items you would like if the
  # location you're requesting from is configured as item commentable
  def item_commentable?
    SULRequests::Application.config.item_commentable_libraries.include?(origin) &&
      holdings.one? &&
      holdings_object.mhld.present?
  end

  def request_commentable?
    false
  end
end
