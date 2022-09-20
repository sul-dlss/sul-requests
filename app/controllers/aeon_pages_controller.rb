# frozen_string_literal: true

###
#  Controller to handle particular behaviors for requests to Aeon
###
class AeonPagesController < RequestsController
  protected

  def validate_request_type
    raise NotAnAeonPageableItemError unless current_request.aeon_pageable?
  end

  class NotAnAeonPageableItemError < StandardError
  end
end
