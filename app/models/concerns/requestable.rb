# frozen_string_literal: true

# Check if a resource is requestable
module Requestable
  def requestable_with_name_email?
    Ability.anonymous.can?(:create, self)
  end

  def requestable_with_university_id?
    Ability.with_a_univ_id.can?(:create, self)
  end
end
