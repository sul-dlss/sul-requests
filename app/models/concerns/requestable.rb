# frozen_string_literal: true

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

  def requires_additional_user_validation?
    requestable_with_library_id? || requestable_by_all?
  end
end
