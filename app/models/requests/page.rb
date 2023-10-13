# frozen_string_literal: true

###
#  Request class for making simple page requests
###
class Page < (Settings.features.migration ? MediatedPage : Request)
  validate :page_validator
  validates :destination, presence: true
  validate :destination_is_a_pickup_library

  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def default_needed_date
    [Time.zone.parse('2023-08-31'), Time.zone.now].max
  end

  def requires_needed_date?
    Settings.features.migration ? true : false
  end

  def needed_date
    return super unless Settings.features.migration

    super || default_needed_date
  end

  private

  def send_confirmation!
    return unless Settings.features.migration

    RequestStatusMailer.request_status_for_page(self).deliver_later if notification_email_address.present?
  end

  def mediated_page_validator
    page_validator
  end

  def page_validator
    errors.add(:base, 'This item is not pageable') unless pageable?
  end

  def needed_date_is_valid
    true
  end
end
