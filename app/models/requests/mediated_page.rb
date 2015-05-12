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

  def requestable_by_all?
    return false if origin == 'HOPKINS'
    true
  end

  def requestable_with_sunet_only?
    return true if origin == 'HOPKINS'
    false
  end

  private

  def commentable_library_whitelist
    %w(SPEC-COLL)
  end

  def mediated_page_validator
    errors.add(:base, 'This item is not mediatable') unless mediateable?
  end
end
