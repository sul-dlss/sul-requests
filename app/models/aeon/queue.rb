# frozen_string_literal: true

module Aeon
  # Model an Aeon queue. Queues are the valid "states" for Aeon requests, set in the Aeon customization manager.
  class Queue
    attr_accessor :id, :queue_name, :display_name, :state_code, :internal_code

    def self.from_dynamic(dyn)
      new(
        id: dyn['id'],
        queue_name: dyn['queueName'],
        display_name: dyn['displayName'],
        state_code: dyn['stateCode'],
        internal_code: dyn['internalCode'],
        active: dyn['active'],
        include_in_request_limit: dyn['includeInRequestLimit'],
        queue_type: dyn['queueType']
      )
    end

    def initialize(id:, queue_name: nil, display_name: nil, state_code: nil, # rubocop:disable Metrics/ParameterLists
                   internal_code: nil, active: nil, include_in_request_limit: nil, queue_type: nil)
      @id = id
      @queue_name = queue_name
      @display_name = display_name
      @state_code = state_code
      @internal_code = internal_code
      @active = active
      @include_in_request_limit = include_in_request_limit
      @queue_type = queue_type
    end

    def active?
      @active
    end

    def include_in_request_limit?
      @include_in_request_limit
    end

    def type
      @queue_type.downcase.to_sym
    end

    def cancelled?
      cancelled_queue_names&.include?(queue_name)
    end

    def draft?
      draft_queue_names&.include?(queue_name)
    end

    def completed?
      completed_queue_names&.include?(queue_name)
    end

    private

    def cancelled_queue_names
      Settings.aeon.queue_names.cancelled[type]
    end

    def completed_queue_names
      Settings.aeon.queue_names.completed[type]
    end

    def draft_queue_names
      Settings.aeon.queue_names.draft[type]
    end
  end
end
