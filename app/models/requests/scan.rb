# frozen_string_literal: true

###
#  Request class for requesting materials to be scanned
###
class Scan < Request
  include Illiadable

  validate :scannable_validator
  validates :section_title, presence: true

  def item_limit
    1
  end

  def destination
    'SCAN'
  end

  def send_approval_status!
    RequestStatusMailer.request_status_for_scan(self).deliver_later if notification_email_address.present?
  end

  # Returns true if a background job was enqueued.
  def submit!
    SubmitIlliadRequestJob.perform_later(id).tap do
      # This ensures that only scan rules with a destination get sent to the ILS.
      # We no longer want to send SAL3 requests to the ILS as this is handled by the ILLiad integration.
      # SAL1/2 requests still go to the ILS at this time.
      send_to_ils_later! if scan_destination&.dig(:patron_barcode).present?
    end
  end

  def special_illiad_request_params
    {
      RequestType: 'Article',
      SpecIns: 'Scan and Deliver Request',
      PhotoJournalTitle: bib_data.title,
      PhotoArticleAuthor: bib_data.author,
      Location: origin,
      ReferenceNumber: origin_location,
      PhotoArticleTitle: section_title,
      PhotoJournalInclusivePages: page_range
    }
  end

  private

  def requested_item_is_not_scannable_only
    # leave blank so scannable only validations are not run for scans
  end

  def scannable_validator
    errors.add(:base, 'This item is not scannable') unless scannable?
  end
end
