# frozen_string_literal: true

###
#  Request class for making page requests that require mediation
###
class MediatedPage < Request
  enum approval_status: { unapproved: 0, marked_as_done: 1, approved: 2 }

  scope :completed, lambda {
    where(approval_status: MediatedPage.approval_statuses.except('unapproved').values).needed_date_desc
  }
  scope :archived, -> { where('needed_date < ?', Time.zone.today).order(needed_date: :desc) }
  scope :for_origin, ->(origin) { where('origin = ? OR origin_location = ?', origin, origin) }

  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def submit!
    # creating a mediated page should not submit the request to ILS (it needs to wait for approvals)
    send_confirmation!
    notify_mediator!

    true
  end

  def all_approved?
    item_statuses.all?(&:approved?)
  end

  def item_statuses
    return to_enum(:item_statuses) unless block_given?

    (barcodes || []).each do |item|
      yield item_status(item)
    end
  end

  def notify_mediator!
    return unless mediator_notification_email_address.present? && Settings.features.mediator_email

    MediationMailer.mediator_notification(self).deliver_later
  end

  def mediator_notification_email_address
    Rails.application.config.mediator_contact_info.fetch(
      origin,
      Rails.application.config.mediator_contact_info.fetch(origin_location, {})
    )[:email]
  end

  def send_approval_status!
    true
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

  def self.needed_dates_for_origin_after_date(origin:, date:)
    for_origin(origin).where('needed_date > ?', date).distinct.pluck(:needed_date).sort
  end

  def default_needed_date
    nil
  end

  private

  def send_confirmation!
    RequestStatusMailer.request_status_for_mediatedpage(self).deliver_later if notification_email_address.present?
  end
end
