# frozen_string_literal: true

###
#  Request class for requesting materials to be scanned
###
class Scan < Request
  def item_limit
    1
  end

  def destination
    'SCAN'
  end

  def send_approval_status!
    RequestStatusMailer.request_status_for_scan(self).deliver_later if notification_email_address.present?
  end

  # Returns true if a background job was enqueued.
  def submit!; end
end
