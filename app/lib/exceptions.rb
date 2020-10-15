# frozen_string_literal: true

# Generic location for custom exceptions
module Exceptions
  class CdlCheckoutError < StandardError; end
  class CdlCheckinError < StandardError; end

  # deal with Symphony's errors..
  class SymphonyError < StandardError
    attr_reader :messages

    def initialize(messages = [])
      @messages = Array(messages) || []
    end

    def message
      @messages.pluck('message').join("\n")
    end

    def privileges_error?
      @messages.pluck('message').any? { |m| m&.starts_with?('User') || m&.starts_with?('Privilege') }
    end
  end
end
