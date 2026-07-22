# frozen_string_literal: true

# A single requested item
class PatronRequestItem < ApplicationRecord
  belongs_to :patron_request
  has_many :admin_comments, as: :request, dependent: :delete_all

  store :data, accessors: [
    :barcode, :migrated_item_id_or_barcode,
    :scan_page_range, :scan_authors, :scan_title,
    :estimated_delivery, :item_title, :mediation_data,
    :ead_url,
    :title, :hierarchy, :for_publication, :requested_pages, :additional_information, :appointment_id, :activity_ids
  ], coder: JSON

  after_initialize :update_item_metadata, if: -> { migrated_item_id_or_barcode.blank? && item_id.blank? && !persisted? }

  attr_writer :barcode_or_item_id

  def update_item_metadata # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity,Metrics/MethodLength
    return if item_id.blank? && barcode.blank? && @barcode_or_item_id.blank?

    barcode_or_item_id = @barcode_or_item_id || barcode || item_id

    @folio_item = patron_request.folio_instance&.items&.find do |i|
      (i.barcode.present? && i.barcode == barcode_or_item_id) || i.id == barcode_or_item_id
    end

    # if we can't find the item in folio, stash the information we do have and hope for the best.
    if @folio_item.blank?
      self.item_id ||= @barcode_or_item_id
      self.barcode ||= @barcode_or_item_id
      return
    end

    self.item_id = @folio_item.id
    self.barcode = @folio_item.barcode
    self.item_callnumber = @folio_item.callnumber
  end

  def folio_item
    return if ead_url

    @folio_item ||= patron_request.folio_instance.items.find do |i|
      i.id == item_id || (i.barcode.present? && i.barcode == barcode) || i.id == barcode
    end
  end

  def approved?
    mediation_data&.dig('approved') == true
  end

  def error?
    mediation_data&.dig('error').present?
  end

  def item_id
    update_record_from_folio if migrated_item_id_or_barcode.present?

    super
  end

  def barcode
    update_record_from_folio if migrated_item_id_or_barcode.present?

    super
  end

  def item_callnumber
    update_record_from_folio if migrated_item_id_or_barcode.present?

    super
  end

  def mediation_data
    update_record_from_folio if migrated_item_id_or_barcode.present?

    super
  end

  def update_record_from_folio # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
    return if ead_url || migrated_item_id_or_barcode.blank?

    @folio_item ||= patron_request.folio_instance.items.find do |i|
      i.id == migrated_item_id_or_barcode || (i.barcode.present? && i.barcode == migrated_item_id_or_barcode)
    end

    return if @folio_item.blank?

    self.migrated_item_id_or_barcode = nil
    self.item_id = @folio_item.id
    self.barcode = @folio_item.barcode
    self.item_callnumber = @folio_item.callnumber
    self.mediation_data = (patron_request.data.dig('item_mediation_data', @folio_item.id) if @folio_item)

    aeon_item = patron_request.data.dig('aeon_item', @folio_item.id)

    assign_attributes(**aeon_item.slice(:title, :hierarchy, :for_publication, :requested_pages, :additional_information, # rubocop:disable Style/MultilineIfModifier
                                        :appointment_id)) if aeon_item.present?
    save
  end
end
