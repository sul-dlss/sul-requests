# frozen_string_literal: true

###
#  Methods for managing requests to the Ils
module IlsRequest
  extend ActiveSupport::Concern

  def ils_request_job
    Settings.ils.request_job.constantize
  end

  def send_to_ils_now!(options = {})
    ils_request_job.perform_now(id, options)
  end

  def send_to_ils_later!(options = {})
    ils_request_job.perform_later(id, options)
  end

  # This is used only in the debug view
  def ils_request_command
    ils_request_job.command.new(self)
  end

  # NOTE: symphony_response_data is stored in the JSON in the "data" column
  def ils_response
    @symphony_response ||= SymphonyResponse.new(symphony_response_data || {})
  end

  def ils_response_will_change!
    @symphony_response = nil
  end

  # Called by SubmitSymphonyRequestJob
  def merge_ils_response_data(new_response)
    self.symphony_response_data = new_response.as_json.with_indifferent_access.tap do |h|
      h['requested_items'] = new_response.items_by_barcode.reverse_merge(ils_response.items_by_barcode).values
    end

    ils_response_will_change!
  end
end
