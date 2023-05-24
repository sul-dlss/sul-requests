# frozen_string_literal: true

###
#  Request class for requesting materials to be scanned
###
class Scan < Request
  validate :scannable_validator
  validates :section_title, presence: true

  def item_limit
    1
  end

  def destination
    'SCAN'
  end

  def submit!
    SubmitScanRequestJob.perform_later(self)
  end

  def illiad_error?
    illiad_response_data['Message'].present?
  end

  def notify_ilb!
    IlbMailer.ilb_notification(self).deliver_later
  end

  def send_approval_status!
    RequestStatusMailer.request_status_for_scan(self).deliver_later if notification_email_address.present?
  end

  private

  def requested_item_is_not_scannable_only
    # leave blank so scannable only validations are not run for scans
  end

  def scannable_validator
    errors.add(:base, 'This item is not scannable') unless scannable?
  end
end
