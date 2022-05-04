# frozen_string_literal: true

# Check if a resource is requestable
module Requestable
  def requestable_with_name_email?
    false
  end

  def requestable_with_library_id?
    requestable_with_name_email? || false
  end

  def validate_library_id?
    requestable_with_library_id? && !requestable_with_name_email?
  end

  def requires_additional_user_validation?
    requestable_with_library_id? || requestable_with_name_email?
  end
end
