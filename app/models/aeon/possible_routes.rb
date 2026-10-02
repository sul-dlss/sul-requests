# frozen_string_literal: true

module Aeon
  # Wrap the request routes response for a transaction
  class PossibleRoutes
    def self.from_dynamic(dyn)
      new(transaction_statuses: dyn['transactionStatuses'], photoduplication_statuses: dyn['photoduplicationStatuses'])
    end

    attr_reader :transaction_statuses, :photoduplication_statuses

    def initialize(transaction_statuses: [], photoduplication_statuses: [])
      @transaction_statuses = transaction_statuses
      @photoduplication_statuses = photoduplication_statuses
    end
  end
end
