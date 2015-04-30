###
#  Request class for making page requests that require mediation
###
class MediatedPage < Request
  validate :mediated_page_validator

  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def commentable?
    commentable_library_whitelist.include?(origin)
  end

  private

  def commentable_library_whitelist
    %w(SPEC-COLL)
  end

  def mediated_page_validator
    errors.add(:base, 'This item is not mediatable') unless mediateable?
  end
end
