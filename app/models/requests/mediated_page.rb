###
#  Request class for making page requests that require mediation
###
class MediatedPage < Request
  enum approval_status: { unapproved: 0, marked_as_done: 1, approved: 2 }

  validate :mediated_page_validator
  validates :destination, presence: true
  validate :needed_date_is_required
  validate :destination_is_a_pickup_library
  validate :needed_date_is_valid, on: :create, if: :requires_needed_date?

  scope :completed, -> { where(approval_status: MediatedPage.approval_statuses.except('unapproved').values) }
  scope :archived, -> { where('needed_date < ?', Time.zone.today).order(needed_date: :desc) }
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
    Rails.application.config.mediator_contact_info.fetch(
      origin,
      Rails.application.config.mediator_contact_info.fetch(origin_location, {})
    )[:email]
  end

  def self.mark_all_archived_as_complete!
    archived.find_each do |mediated_page|
      if mediated_page.all_approved?
        mediated_page.approved!
      else
        mediated_page.marked_as_done!
      end
    end
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
