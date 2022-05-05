# frozen_string_literal: true

###
#  Request class for making simple page requests
###
class Page < Request
  validate :page_validator
  validates :destination, presence: true
  validate :destination_is_a_pickup_library

  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  # Ideally, we'll be able to drop the wildcard rule because no requests will make it here
  after_create do
    next unless location_rule&.send_honeybadger_notice_if_used

    Honeybadger.notify("WARNING: Using default location rule for page #{id} (origin: #{origin}, origin_location: #{origin_location})")
  end

  private

  def page_validator
    errors.add(:base, 'This item is not pageable') unless pageable?
  end
end
