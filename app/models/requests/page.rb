###
#  Request class for making simple page requests
###
class Page < Request
  def commentable?
    return super unless origin == 'SAL-NEWARK'
    true
  end
end
