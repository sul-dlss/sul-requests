# frozen_string_literal: true

###
#  Request class for making simple page requests
###
class Page < Request
  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def requires_needed_date?
    false
  end
end
