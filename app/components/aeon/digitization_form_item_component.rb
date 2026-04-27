# frozen_string_literal: true

module Aeon
  # Render an accordion item for a digitization form step.
  class DigitizationFormItemComponent < ViewComponent::Base
    attr_reader :title, :dom_id, :object, :base_name

    # rubocop:disable Metrics/ParameterLists
    def initialize(title:, dom_id:, object: nil, base_name: nil, accordion: true, container_modal: false)
      @title = title
      @dom_id = dom_id
      @object = object
      @base_name = base_name || "item[#{dom_id}]"
      @accordion = accordion
      @container_modal = container_modal
    end
    # rubocop:enable Metrics/ParameterLists

    def accordion?
      @accordion
    end

    def save_for_later?
      object.nil?
    end

    def container_modal?
      @container_modal
    end
  end
end
