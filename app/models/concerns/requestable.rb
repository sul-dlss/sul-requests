# Check if a resource is requestable
module Requestable
  def requestable_by_all?
    false
  end

  def requestable_with_library_id?
    requestable_by_all? || false
  end

  def requestable_with_sunet_only?
    false
  end
end
