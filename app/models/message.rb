# frozen_string_literal: true

# Messages to be displayed on request forms
class Message < ActiveRecord::Base
  validates :library, :request_type, presence: true
  scope :active, ->(date = Time.zone.now) { where('? BETWEEN start_at AND end_at', date) }
  scope :for_type, ->(type) { where(request_type: type) }

  def active?(date = Time.zone.now)
    start_at <= date && end_at >= date if scheduled?
  end

  def scheduled?
    start_at? && end_at?
  end

  def title
    "#{request_type.titleize} from #{library_name}"
  end

  def self.notification_type(_request)
    'page'
  end

  private

  def library_name
    Folio::Types.libraries.find_by(code: library)&.name || library
  end
end
