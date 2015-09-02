###
#  Request class for requesting materials to be scanned
###
class Scan < Request
  validate :scannable_validator
  validates :section_title, presence: true

  def requestable_with_sunet_only?
    true
  end

  def item_limit
    1
  end

  def appears_in_myaccount?
    false
  end

  private

  def scannable_validator
    errors.add(:base, 'This item is not scannable') unless scannable?
  end
end
