# frozen_string_literal: true

module Aeon
  # Trash-icon button that removes a request from its activity
  class RequestDeleteButtonComponent < ViewComponent::Base
    attr_reader :request

    def initialize(request:)
      @request = request
    end

    def button_label
      if request.activity?
        "Remove #{request.title} from activity"
      else
        "Delete #{request.title} request"
      end
    end

    def request_type
      if request.activity?
        'Activity'
      elsif request.digital?
        'Digitization'
      else
        'Reading room use'
      end
    end

    def render?
      helpers.can?(:destroy, request)
    end
  end
end
