# frozen_string_literal: true

# A single requested item
class PatronRequestItem < ApplicationRecord
  belongs_to :patron_request
  has_many :api_responses, dependent: :delete_all
  has_many :folio_api_responses, dependent: :delete_all
  has_many :illiad_api_responses, dependent: :delete_all
  has_many :aeon_api_responses, dependent: :delete_all
  has_many :admin_comments, as: :request, dependent: :delete_all
  delegate :patron, to: :patron_request

  store :data, accessors: [
    :barcode, :migrated_item_id_or_barcode,
    :scan_page_range, :scan_authors, :scan_title,
    :estimated_delivery, :item_title, :mediation_data,
    :ead_url,
    :title, :hierarchy, :for_publication, :requested_pages, :additional_information, :appointment_id, :activity_ids
  ], coder: JSON

  before_save :update_item_metadata, if: -> { item_id_changed? || patron_request_id_changed? }

  def item_id=(value)
    super
    update_item_metadata
  end

  def latest_api_response
    @latest_api_response ||= api_responses.order(created_at: :desc).first
  end

  def update_item_metadata
    @folio_item = nil

    # if we can't find the item in folio, stash the information we do have and hope for the best.
    return if folio_item.blank?

    self.barcode = folio_item.barcode
    self.item_callnumber = folio_item.callnumber
  end

  def illiad_request_params
    return nil if folio_item.blank?

    patron_request.illiad_request_params(folio_item)
  end

  def folio_item
    return if ead_url || patron_request.blank?

    @folio_item ||= patron_request.folio_instance.items.find do |i|
      i.id == item_id
    end
  end

  def approved?
    mediation_data&.dig('approved') == true
  end

  def error?
    mediation_data&.dig('error').present?
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

    patron_request.folio_api_responses.where(item_id: item_id).update_all(patron_request_item_id: id) # rubocop:disable Rails/SkipsModelValidations
    patron_request.illiad_api_responses.where(item_id: item_id).update_all(patron_request_item_id: id) # rubocop:disable Rails/SkipsModelValidations
    patron_request.aeon_api_responses.where(item_id: item_id).update_all(patron_request_item_id: id) # rubocop:disable Rails/SkipsModelValidations

    save
  end
end
