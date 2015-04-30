###
#  Mixin to encapsulate defining if a request is scannable
###
module Scannable
  def scannable?
    @library == 'SAL3' && @location == 'STACKS'
  end
end
