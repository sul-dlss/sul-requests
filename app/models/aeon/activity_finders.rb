# frozen_string_literal: true

module Aeon
  # Wraps a group of Aeon activities with finder methods
  class ActivityFinders
    include Enumerable
    include ScheduledFinders

    attr_reader :activities

    delegate :each, :-, :+, :present?, :blank?, :length, :count, :to_ary, to: :activities

    def initialize(activities)
      @activities = activities
    end

    def find(id_or_ids = nil, &)
      return super(&) if block_given?

      if id_or_ids.is_a?(Array)
        ids = id_or_ids.map(&:to_i)
        self.class.new(activities.select { |activity| ids.include?(activity.id) })
      else
        id = id_or_ids.to_i
        activities.find { |activity| activity.id == id }
      end
    end

    def select(&)
      self.class.new(activities.select(&))
    end

    def reject(&)
      self.class.new(activities.reject(&))
    end

    def active
      self.class.new(activities.select(&:active?))
    end

    def past
      self.class.new(activities.reject(&:active?))
    end
  end
end
