# frozen_string_literal: true

# Render an accordion step
class AccordionStepComponent < ViewComponent::Base
  renders_one :title
  renders_one :body

  attr_reader :step_index, :id, :classes, :data, :patron_request_data, :form_id, :request

  # rubocop:disable Metrics/ParameterLists
  def initialize(id:,
                 step_index: -1,
                 classes: [],
                 data: {},
                 form_id: nil,
                 request: nil,
                 submit: false,
                 cancel: true,
                 submit_text: nil)
    @id = id
    @step_index = step_index
    @classes = classes
    @data = data
    @form_id = form_id
    @submit = submit
    @cancel = cancel
    @item_request = request
    @submit_text = submit_text
  end
  # rubocop:enable Metrics/ParameterLists

  def expanded?
    step_index == 1
  end

  def submit?
    @submit
  end

  def submit_text
    @submit_text || t('patron_requests.new.submit')
  end

  def cancel?
    @cancel
  end

  delegate :instance_hrid, :origin_location_code, to: :@item_request
end
