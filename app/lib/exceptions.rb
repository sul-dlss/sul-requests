# frozen_string_literal: true

# Generic location for custom exceptions
module Exceptions
  class CdlCheckoutError < StandardError; end
  class CdlCheckinError < StandardError; end
  class SymphonyError < StandardError; end
end
