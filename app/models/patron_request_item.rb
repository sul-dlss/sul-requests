# frozen_string_literal: true

# A single requested item
class PatronRequestItem < ApplicationRecord
  belongs_to :patron_request
  has_many :admin_comments, as: :request, dependent: :delete_all

  store :data, accessors: [
    :barcode,
    :scan_page_range, :scan_authors, :scan_title,
    :estimated_delivery, :item_title, :mediation_data,
    :ead_url,
    :title, :hierarchy, :for_publication, :requested_pages, :additional_information, :appointment_id, :activity_ids
  ], coder: JSON

  def folio_item
    return if ead_url

    @folio_item ||= patron_request.folio_instance.items.find { |i| i.id == item_id }
  end
end
