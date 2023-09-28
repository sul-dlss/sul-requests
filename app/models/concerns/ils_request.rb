# frozen_string_literal: true

###
#  Methods for managing requests to the Ils
module IlsRequest
  extend ActiveSupport::Concern
  included do
    class_attribute :ils_job_class, default: Settings.ils.request_job.constantize
  end

  def send_to_ils_now!(options = {})
    ils_job_class.perform_now(id, options)
  end

  def send_to_ils_later!(options = {})
    ils_job_class.perform_later(id, options)
  end

  # This is used only in the debug view
  def ils_request_command
    ils_job_class.command.new(self, logger:)
  end

  # NOTE: symphony_response_data + folio_response_data are stored in the JSON in the "data" column
  def ils_response
    @ils_response ||= FolioResponse.new(ils_response_data)
  end

  def ils_response_data
    folio_response_data || symphony_response_data || {}
  end

  def ils_response_will_change!
    @ils_response = nil
  end

  # Called by SubmitSymphonyRequestJob
  def merge_ils_response_data(new_response)
    merged_data = new_response.as_json.with_indifferent_access.tap do |h|
      h['requested_items'] = new_response.items_by_barcode.reverse_merge(ils_response.items_by_barcode).values
    end

    method = new_response.is_a?(FolioResponse) ? :folio_response_data= : :symphony_response_data=

    public_send(method, merged_data)

    ils_response_will_change!
  end
end
