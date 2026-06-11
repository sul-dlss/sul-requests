# frozen_string_literal: true

module StubAeonClient
  # :nodoc:
  class Queue < AeonRecord
    store :data, accessors: [:queueName, :displayName, :stateCode, :internalCode, :active, :includeInRequestLimit, :queueType, :menuGroup],
                 coder: JSON

    def as_json(*)
      data.as_json(*).merge('id' => id)
    end
  end
end
