###
#  Request class for making simple page requests
###
class Page < Request
  validate :page_validator

  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def commentable?
    return super unless origin == 'SAL-NEWARK'
    true
  end

  private

  def page_validator
    errors.add(:base, 'This item is not pageable') unless pageable?
  end
end
