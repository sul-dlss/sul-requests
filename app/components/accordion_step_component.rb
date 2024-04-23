# frozen_string_literal: true

# Render an accordion step
class AccordionStepComponent < ViewComponent::Base
  renders_one :title
  renders_one :body

  attr_reader :step_index, :id, :classes, :data, :patron_request_data, :form_id, :request

  def initialize(id:, step_index: -1, classes: [], data: {}, form_id: nil, request: nil, submit: false) # rubocop:disable Metrics/ParameterLists
    @id = id
    @step_index = step_index
    @classes = classes
    @data = data
    @form_id = form_id
    @submit = submit
    @request = request
  end

  def expanded?
    step_index == 1
  end

  def submit?
    @submit
  end
end
