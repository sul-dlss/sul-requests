# frozen_string_literal: true

###
#  Request class for making simple page requests
###
class Page < Request
  REQUESTALBE_BY_SUNET_OR_LIBRARY_ONLY = ['MEDIA-MTXT'].freeze
  validate :page_validator
  validates :destination, presence: true
  validate :destination_is_a_pickup_library

  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def requestable_by_all?
    return false if REQUESTALBE_BY_SUNET_OR_LIBRARY_ONLY.include?(origin)

    true
  end

  def requestable_with_library_id?
    return true if REQUESTALBE_BY_SUNET_OR_LIBRARY_ONLY.include?(origin)

    super
  end

  private

  def page_validator
    errors.add(:base, 'This item is not pageable') unless pageable?
  end
end
