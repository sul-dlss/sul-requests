# frozen_string_literal: true

# Mixin for requests that can be sent to ILLiad
module Illiadable
  def notify_ilb!
    IlbMailer.ilb_notification(self).deliver_later
  end

  def illiad_error?
    return false if illiad_response_data.blank?

    illiad_response_data['Message'].present?
  end

  def illiad_request_params
    IlliadRequestParameters.build(self)
  end
end
