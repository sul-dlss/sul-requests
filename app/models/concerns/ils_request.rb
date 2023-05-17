# frozen_string_literal: true

###
#  Methods for managing requests to the Ils
module IlsRequest
  extend ActiveSupport::Concern

  def ils_request_job
    Settings.features.ils == 'symphony' ? SubmitSymphonyRequestJob : SubmitFolioRequestJob
  end

  def send_to_ils_now!(options = {})
    ils_request_job.perform_now(id, options)
  end

  def send_to_ils_later!(options = {})
    ils_request_job.perform_later(id, options)
  end

  # This is used only in the debug view
  def symphony_request
    ils_request_job.command.new(self)
  end

  # NOTE: symphony_response_data is stored in the JSON in the "data" column
  def symphony_response
    @symphony_response ||= SymphonyResponse.new(symphony_response_data || {})
  end

  def symphony_response_will_change!
    @symphony_response = nil
  end

  # Called by SubmitSymphonyRequestJob
  def merge_symphony_response_data(new_response)
    self.symphony_response_data = new_response.as_json.with_indifferent_access.tap do |h|
      h['requested_items'] = new_response.items_by_barcode.reverse_merge(symphony_response.items_by_barcode).values
    end

    symphony_response_will_change!
  end
end
