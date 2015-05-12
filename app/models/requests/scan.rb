###
#  Request class for requesting materials to be scanned
###
class Scan < Request
  validate :scannable_validator

  def requestable_with_sunet_only?
    true
  end

  private

  def scannable_validator
    errors.add(:base, 'This item is not scannable') unless scannable?
  end
end
