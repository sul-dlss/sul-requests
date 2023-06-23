# frozen_string_literal: true

module Folio
  # Location information in FOLIO, analogous to LibraryLocation for Symphony
  class Location
    # Location details, used for configuration storage
    Details = Struct.new(:page_aeon_site,
                         :page_mediation_group_key,
                         :page_service_points,
                         :scan_service_point,
                         :scan_pseudopatron_barcode,
                         :scan_material_types,
                         keyword_init: true) do
      def self.from_dynamic(json)
        new(page_aeon_site: json.fetch('scanAeonSite', nil),
            page_mediation_group_key: json.fetch('scanMediationGroupKey', nil),
            page_service_points: json.fetch('pageServicePoints', []),
            scan_service_point: json.fetch('scanServicePoint', nil),
            scan_pseudopatron_barcode: json.fetch('scanPseudopatronBarcode', nil),
            scan_material_types: json.fetch('scanMaterialTypes', []))
      end
    end

    attr_reader :id, :code, :name

    def initialize(id:, code:, name:, details: {})
      @id = id
      @code = code
      @name = name
      @details = Details.new(**details.symbolize_keys)
    end

    def self.from_dynamic(json)
      new(id: json.fetch('id'),
          code: json.fetch('code'),
          name: json.fetch('name'),
          details: Details.from_dynamic(json['details'] || {}))
    end

    # Set of rules governing paging, scanning, etc.
    def rules
      [paging_rule, scanning_rule].compact
    end

    private

    # Rule governing paging of material at this location, if enabled
    def paging_rule
      return unless @details.page_aeon_site.present? || @details.page_mediation_group_key.present? || @details.page_service_points.present?

      Folio::LocationRules::PagingRule.new(
        self,
        aeon_site: @details.page_aeon_site,
        mediation_group_key: @details.page_mediation_group_key,
        service_points: @details.page_service_points
      )
    end

    # Rule governing scanning of material at this location, if enabled
    def scanning_rule
      return if @details.scan_pseudopatron_barcode.blank?

      Folio::LocationRules::ScanningRule.new(
        self,
        pseudopatron_barcode: @details.scan_pseudopatron_barcode,
        material_types: @details.scan_material_types,
        service_point: @details.scan_service_point
      )
    end
  end
end
