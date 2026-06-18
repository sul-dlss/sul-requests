# frozen_string_literal: true

module Home
  # Submits the patron's outstanding fines to /payments.
  class PayNowFormComponent < ViewComponent::Base
    attr_reader :fines, :balance, :patron_key, :button_class

    def initialize(fines:, balance:, patron_key:, button_class: 'btn btn-sm btn-secondary')
      @fines = fines
      @balance = balance
      @patron_key = patron_key
      @button_class = button_class
    end
  end
end
