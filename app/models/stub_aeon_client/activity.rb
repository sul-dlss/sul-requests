# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class Activity < AeonRecord
    store :data, accessors: [:users, :beginDate, :endDate, :name, :active, :location, :activityType, :activityStatus], coder: JSON

    def as_json(*)
      data.as_json(*).merge('id' => id)
    end
  end
end
