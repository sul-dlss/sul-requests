# frozen_string_literal: true

# Check if a resource is requestable
module Requestable
  def requestable_with_name_email?
    Ability.anonymous.can?(:create, self)
  end

  def requestable_with_library_id?
    Ability.with_a_library_id.can?(:create, self)
  end
end
