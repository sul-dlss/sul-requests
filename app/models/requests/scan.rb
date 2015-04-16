###
#  Request class for requesting materials to be scanned
###
class Scan < Request
  validate :scannable_validator

  private

  def scannable_validator
    errors.add(:base, 'This item is not scannable') unless scannable?
  end
end
