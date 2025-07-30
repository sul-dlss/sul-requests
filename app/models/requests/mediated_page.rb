# frozen_string_literal: true

###
#  Request class for making page requests that require mediation
###
class MediatedPage < Request
  enum :approval_status, { unapproved: 0, marked_as_done: 1, approved: 2 }

  scope :completed, lambda {
    where(approval_status: MediatedPage.approval_statuses.except('unapproved').values).needed_date_desc
  }
  scope :archived, -> { where(needed_date: ...Time.zone.today).order(needed_date: :desc) }
  scope :for_origin, ->(origin) { where('origin = ? OR origin_location = ?', origin, origin) }

  include TokenEncryptable

  def token_encryptor_attributes
    super << user.email
  end

  def all_approved?
    item_statuses.all?(&:approved?)
  end

  def item_statuses
    return to_enum(:item_statuses) unless block_given?

    (barcodes || []).each do |item|
      yield item_status(item)
    end
  end

  def default_needed_date
    nil
  end
end
