##
# Default options for request workflows
module DefaultRequestOptions
  extend ActiveSupport::Concern

  def item_limit
    nil
  end

  def requires_needed_date?
    false
  end
end
