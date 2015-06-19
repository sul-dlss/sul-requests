###
#  Mixin to define commentable behavior in request objects
###
module Commentable
  # Used for adding ad-hoc items that are not listed in the holdings
  def ad_hoc_item_commentable?
    false
  end

  # Currently used to comment which items you would like if the
  # location you're requesting from does not have any barcoded items
  def item_commentable?
    false
  end

  def request_commentable?
    false
  end
end
