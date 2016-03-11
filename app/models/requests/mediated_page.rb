###
#  Request class for making page requests that require mediation
###
class MediatedPage < Request
  validate :mediated_page_validator
  validates :destination, presence: true
  validate :needed_date_is_required
  validate :destination_is_a_pickup_library
  validate :needed_date_is_valid, on: :create, if: :requires_needed_date?

  scope :archived, -> { where('needed_date < ?', Time.zone.today) }
  scope :active, -> { where('needed_date IS NULL OR needed_date >= ?', Time.zone.today) }
  scope :for_origin, ->(origin) { where('origin = ? OR origin_location = ?', origin, origin) }

  include TokenEncryptable

  after_create :notify_mediator!

  def token_encryptor_attributes
    super << user.email
  end

  def request_commentable?
    commentable_library_whitelist.include?(origin)
  end

  def requestable_by_all?
    return false if origin == 'HOPKINS'
    true
  end

  def requestable_with_sunet_only?
    return true if origin == 'HOPKINS'
    false
  end

  def item_limit
    return 5 if origin == 'SPEC-COLL'
    return 5 if origin == 'RUMSEYMAP'
    return 20 if origin == 'HV-ARCHIVE'
    super
  end

  def requires_needed_date?
    return false if origin == 'HOPKINS'
    return false if origin_location == 'PAGE-MP'
    true
  end

  def submit!
    # creating a mediated page should not submit the request to Symphony
    true
  end

  def all_approved?
    ((barcodes || []) + (ad_hoc_items || [])).all? do |item|
      item_status(item).approved?
    end
  end

  def notify_mediator!
    MediationMailer.mediator_notification(self).deliver_later if mediator_notification_email_address.present?
  end

  def mediator_notification_email_address
    Rails.application.config.mediator_contact_info.fetch(origin, {})[:email]
  end

  private

  def needed_date_is_required
    errors.add(:needed_date, "can't be blank") if needed_date.blank? && requires_needed_date?
  end

  def commentable_library_whitelist
    %w(SPEC-COLL)
  end

  def mediated_page_validator
    errors.add(:base, 'This item is not mediatable') unless mediateable?
  end

  def needed_date_is_valid
    errors.add(:needed_date, 'The library is not open on that date') unless PagingSchedule.for(self).valid?(needed_date)
  rescue PagingSchedule::ScheduleNotFound
    nil
  end
end
