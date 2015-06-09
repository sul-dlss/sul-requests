###
#  Mixin to define commentable behavior in request objects
###
module Commentable
  def item_commentable?
    false
  end

  def request_commentable?
    false
  end
end
