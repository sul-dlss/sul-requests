###
#  Symphony methods for sending and managing requests in symphony
module SymphonyRequest
  def appears_in_myaccount?
    user.webauth_user?
  end

  def send_to_symphony!(options = {})
    SubmitSymphonyRequestJob.perform_now(self, options)
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
end
