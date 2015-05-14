###
#  Main Request class.  All other requests use
#  STI and sub-class this main request class.
###
class Request < ActiveRecord::Base
  delegate :scannable?, :mediateable?, :pageable?, to: :library_location

  validates :item_id, :origin, :origin_location, presence: true

  serialize :data, Hash
  serialize :barcodes, Array

  belongs_to :user, autosave: true
  accepts_nested_attributes_for :user

  before_create do
    self.item_title ||= searchworks_item.title
  end

  def library_location
    @library_location ||= LibraryLocation.new(self)
  end

  def searchworks_item
    @searchworks_item ||= SearchworksItem.new(self)
  end

  def send_confirmation!
    return nil if user.library_id_user?
    ConfirmationMailer.request_confirmation(self).deliver_later
  end

  def commentable?
    false
  end

  def delegate_request!
    if mediateable?
      self.becomes!(MediatedPage)
    else
      self.becomes!(Page)
    end
  end

  def stored_or_fetched_item_title
    if persisted?
      item_title
    else
      searchworks_item.title
    end
  end

  # This method gets called when saving the user assocation
  # and allows us to make sure we assign the user object if
  # there already is one associated with that email address
  def autosave_associated_records_for_user
    return unless user
    if (existing_user = find_existing_user)
      self.user = existing_user
    else
      user.save!
      self.user = user
    end
  end

  def find_existing_user
    return unless user
    if user.webauth_user?
      User.find_by_webauth(user.webauth)
    elsif user.non_webauth_user?
      User.find_by_email(user.email)
    end
  end

  def holdings
    @holdings ||= begin
      if persisted?
        searchworks_item.requested_holdings.by_barcodes(barcodes)
      else
        searchworks_item.requested_holdings.items
      end
    end
  end

  def requestable_by_all?
    false
  end

  def requestable_with_library_id?
    requestable_by_all? || false
  end

  def requestable_with_sunet_only?
    false
  end

  def item_limit
    nil
  end

  def data_to_email_s
    %w(comments page_range section_title authors).map do |field|
      if (data_field = data[field]).present?
        "#{I18n.t("forms.#{self.class.name}.labels.#{field}",
                  default: I18n.t("forms.labels.#{field}"))}:\n  #{data_field}"
      end
    end.compact.join("\n")
  end

  class << self
    # The mediateable_oirgins will make multiple (efficient) database requests
    # in order to return the array of locations that are both configured as mediateable and have existing requests.
    # Another alternative would be to use (origin_admin_groups & uniq.pluck(:origin)).present? but that will result
    # in a SELECT DISTNICT which could get un-performant with a large table of requests.
    def mediateable_origins
      Settings.origin_admin_groups.to_hash.keys.map(&:to_s).select do |library_origin|
        MediatedPage.exists?(origin: library_origin)
      end
    end
  end
end
