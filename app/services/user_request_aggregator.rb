# frozen_string_literal: true

# Aggregates a user's requests
class UserRequestAggregator
  def initialize(user)
    @user = user
  end

  def all(filter: nil, sort: :created_at)
    # TODO: These might need to be presenters/normalized in some way so we can filter/sort on a common interface
    requests = all_requests_for_user
    requests = apply_filter(requests, filter) if filter
    apply_sort(requests, sort)
  end

  private

  attr_reader :user

  def all_requests_for_user
    aeon_requests
  end

  def aeon_requests
    user.aeon&.requests
  end

  def apply_filter(requests, _filter)
    requests
  end

  def apply_sort(requests, _sort)
    requests
  end
end
