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

  # Ideally, we'll be able to drop the wildcard rule because no requests will make it here
  after_create do
    next if request_abilities.respond_to?(:send_honeybadger_notice_if_used) && !request_abilities&.send_honeybadger_notice_if_used

    Honeybadger.notify("WARNING: Using default location rule for page #{id} (origin: #{origin}, origin_location: #{origin_location})")
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
