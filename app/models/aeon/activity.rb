# frozen_string_literal: true

module Aeon
  # Wraps an Aeon appointment record
  class Activity
    include ActiveModel::Model

    attr_accessor :users, :start_time, :stop_time, :name, :active, :location, :activity_type

    def self.from_dynamic(dyn)
      users = dyn['users'].map { |user| Aeon::User.from_dynamic(user) }
      new(
        users:,
        start_time: dyn['beginDate'] && Time.zone.parse(dyn['beginDate']),
        stop_time: dyn['endDate'] && Time.zone.parse(dyn['endDate']),
        name: dyn['name'],
        active: dyn['active'],
        location: dyn['location'],
        activity_type: dyn['activityType']
      )
    end
  end
end
