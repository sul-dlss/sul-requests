# frozen_string_literal: true

###
#  Symphony methods for sending and managing requests in symphony
module SymphonyRequest
  def appears_in_myaccount?
    user.webauth_user?
  end

  def send_to_symphony_now!(options = {})
    SubmitSymphonyRequestJob.perform_now(id, options)
  end

  def send_to_symphony_later!(options = {})
    SubmitSymphonyRequestJob.perform_later(id, options)
  end

  def symphony_request
    SubmitSymphonyRequestJob::Command.new(self)
  end

  def symphony_response
    @symphony_response ||= SymphonyResponse.new(symphony_response_data || {})
  end

  def symphony_response_will_change!
    @symphony_response = nil
  end

  def merge_symphony_response_data(new_response_data)
    new_response = SymphonyResponse.new(new_response_data)

    self.symphony_response_data = new_response_data.tap do |h|
      h[:requested_items] = new_response.items_by_barcode.reverse_merge(symphony_response.items_by_barcode).values
    end

    symphony_response_will_change!
  end
end
