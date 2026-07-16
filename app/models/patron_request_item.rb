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

  after_initialize :update_item_metadata, if: -> { item_id.blank? || @barcode_or_item_id.present? }
  attr_writer :barcode_or_item_id

  def barcode_or_item_id
    @barcode_or_item_id || barcode || item_id
  end

  def update_item_metadata # rubocop:disable Metrics/AbcSize
    @folio_item = patron_request.folio_instance&.items&.find do |i|
      i.barcode == barcode_or_item_id || i.id == barcode_or_item_id
    end

    self.barcode = barcode_or_item_id and return if @folio_item.blank?

    self.item_id = @folio_item.id
    self.barcode = @folio_item.barcode
    self.item_callnumber = @folio_item.callnumber
  end

  def folio_item
    return if ead_url

    @folio_item ||= patron_request.folio_instance.items.find { |i| i.id == item_id || i.barcode == barcode || i.id == barcode }
  end

  def approved?
    mediation_data&.dig('approved') == true
  end

  def error?
    mediation_data&.dig('error').present?
  end
end
