###
#  Request class for making simple page requests
###
class Page < Request
  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def commentable?
    return super unless origin == 'SAL-NEWARK'
    true
  end
end
