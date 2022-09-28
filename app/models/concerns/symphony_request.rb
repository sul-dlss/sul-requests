# frozen_string_literal: true

###
#  Symphony methods for sending and managing requests in symphony
module SymphonyRequest
  extend ActiveSupport::Concern

  included do
    class_attribute :symphony_job, default: SubmitSymphonyRequestJob
  end

  def send_to_symphony_now!(options = {})
    symphony_job.perform_now(id, options)
  end

  def send_to_symphony_later!(options = {})
    symphony_job.perform_later(id, options)
  end

  def symphony_request
    symphony_job.command.new(self)
  end

  def symphony_response
    @symphony_response ||= SymphonyResponse.new(symphony_response_data || {})
  end

  def symphony_response_will_change!
    @symphony_response = nil
  end

  def merge_symphony_response_data(new_response)
    self.symphony_response_data = new_response.as_json.with_indifferent_access.tap do |h|
      h['requested_items'] = new_response.items_by_barcode.reverse_merge(symphony_response.items_by_barcode).values
    end

    symphony_response_will_change!
  end
end
