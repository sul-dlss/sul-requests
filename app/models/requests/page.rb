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

  def requestable_by_all?
    true
  end

  def item_commentable?
    return super unless origin == 'SAL-NEWARK'
    !barcoded_holdings?
  end

  private

  def page_validator
    errors.add(:base, 'This item is not pageable') unless pageable?
  end
end
