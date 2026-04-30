# frozen_string_literal: true

module Aeon
  # Wraps an Aeon appointment record
  class Activity
    include ActiveModel::Model

    attr_accessor :id, :users, :start_time, :stop_time, :name, :active, :location, :activity_type, :status, :sites

    def self.from_dynamic(dyn) # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      users = dyn['users'].map { |user| Aeon::User.from_dynamic(user) }
      new(
        id: dyn['id'],
        users:,
        start_time: dyn['beginDate'] && Time.zone.parse(dyn['beginDate']),
        stop_time: dyn['endDate'] && Time.zone.parse(dyn['endDate']),
        name: dyn['name'],
        active: dyn['active'],
        location: dyn['location'],
        sites: sites(dyn['location']),
        activity_type: dyn['activityType'],
        status: dyn['activityStatus']
      )
    end

    def completed?
      status == 'Completed'
    end

    def self.sites(location)
      location_mapping = { 'ARS' => ['ARS'], 'David Ramsey Map Center' => ['RUMSEY'], 'East Asia Library' => ['EASTASIA'],
                           nil => %w[ARS RUMSEY EASTASIA SPECUA] }
      return location_mapping[location] if location_mapping.key?(location)

      ['SPECUA']
    end
  end
end
