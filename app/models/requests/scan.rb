###
#  Request class for requesting materials to be scanned
###
class Scan < Request
  validate :scannable_validator
  validates :section_title, presence: true

  def requestable_with_sunet_only?
    true
  end

  def item_limit
    1
  end

  def appears_in_myaccount?
    false
  end

  def item_commentable?
    false
  end

  def destination
    'SCAN'
  end

  def submit!
    send_to_symphony_now!
  end

  def send_confirmation!
    ConfirmationMailer.request_confirmation(self).deliver_later if notification_email_address.present?
  end

  def send_approval_status!
    true
  end

  private

  def scannable_validator
    errors.add(:base, 'This item is not scannable') unless scannable?
  end
end
