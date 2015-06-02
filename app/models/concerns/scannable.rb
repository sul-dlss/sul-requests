###
#  Mixin to encapsulate defining if a request is scannable
###
module Scannable
  def scannable?
    scannable_library? &&
      scannable_location? &&
      includes_scannable_item?
  end

  private

  def scannable_library?
    library == 'SAL3'
  end

  def scannable_location?
    %w(BUS-STACKS STACKS).include?(location)
  end

  def includes_scannable_item?
    request.holdings.any? do |item|
      %w(BUS-STACKS STKS STKS-MONO STKS-PERI).include?(item.type)
    end
  end
end
