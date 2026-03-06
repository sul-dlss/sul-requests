# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class AppointmentDurationSelectorComponent < ViewComponent::Base
    attr_reader :selected, :form

    def initialize(form:, selected: '')
      @selected = selected
      @form = form
    end
  end
end
