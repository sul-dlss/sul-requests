# frozen_string_literal: true

module Folio
  # This class is responsible for loading the types from the FOLIO API and
  # caching them locally. It also provides some convenience methods for
  # accessing the types.
  class Types
    class << self
      delegate  :policies, :circulation_rules, :criteria, :get_type, :locations, :libraries,
                :map_to_library_code, :map_to_service_point_code, :service_point_name, :service_point_code,
                :service_point_id, :valid_service_point_code?, to: :instance
    end

    def self.instance
      @instance ||= new
    end

    attr_reader :cache_dir, :folio_client

    def initialize(cache_dir: Rails.root.join('config/folio'), folio_client: FolioClient.new)
      @cache_dir = cache_dir
      @folio_client = folio_client
    end

    # rubocop:disable Metrics/AbcSize
    def sync!
      @policies = nil
      @criteria = nil

      types_of_interest.each do |type|
        file = cache_dir.join("#{type}.json")

        File.write(file, JSON.pretty_generate(folio_client.public_send(type)))
      end

      circulation_rules = folio_client.circulation_rules
      File.write(cache_dir.join('circulation_rules.txt'), circulation_rules)
      File.write(cache_dir.join('circulation_rules.csv'),
                 Folio::CirculationRules::PolicyService.rules(circulation_rules).map(&:to_csv).join)
    end
    # rubocop:enable Metrics/AbcSize

    def circulation_rules
      file = cache_dir.join('circulation_rules.txt')
      file.read if file.exist?
    end

    def service_points
      get_type('service_points').map { |p| Folio::ServicePoint.from_dynamic(p) }.index_by(&:id)
    end

    def policies
      @policies ||= {
        request: get_type('request_policies').index_by { |p| p['id'] },
        loan: get_type('loan_policies').index_by { |p| p['id'] },
        overdue: get_type('overdue_fines_policies').index_by { |p| p['id'] },
        'lost-item': get_type('lost_item_fees_policies').index_by { |p| p['id'] },
        notice: get_type('patron_notice_policies').index_by { |p| p['id'] }
      }
    end

    # rubocop:disable Metrics/AbcSize
    def criteria
      @criteria ||= {
        'group' => get_type('patron_groups').index_by { |p| p['id'] },
        'material-type' => get_type('material_types').index_by { |p| p['id'] },
        'loan-type' => get_type('loan_types').index_by { |p| p['id'] },
        'location-institution' => get_type('institutions').index_by { |p| p['id'] },
        'location-campus' => get_type('campuses').index_by { |p| p['id'] },
        'location-library' => libraries,
        'location-location' => locations
      }
    end
    # rubocop:enable Metrics/AbcSize

    def libraries
      @libraries ||= get_type('libraries').index_by { |p| p['id'] }
    end

    def locations
      @locations ||= get_type('locations').index_by { |p| p['id'] }
    end

    def get_type(type)
      raise "Unknown type #{type}" unless types_of_interest.include?(type.to_s)

      file = cache_dir.join("#{type}.json")
      JSON.parse(file.read) if file.exist?
    end

    # Mapping and functions for finding specific information
    # For FOLIO, destination is specified as service point
    # Convert service point to library for scheduling and library hours
    def map_to_library_code(service_point_code)
      return service_point_code if service_point_code == 'SCAN'

      return nil unless valid_service_point_code?(service_point_code)

      service_point_id = service_point_id(service_point_code)
      library_id = library_for_service_point(service_point_id)

      # Find the library code associated with this library id
      get_type('libraries').find { |library| library['id'] == library_id }['code']
    end

    # Find the service point ID based on this service point code
    def service_point_id(service_point_code)
      service_points.values.find { |v| v.code == service_point_code }&.id
    end

    # Find the library id for the location with which this service point is associated
    def library_for_service_point(service_point_id)
      loc = get_type('locations').find { |location| location['primaryServicePoint'] == service_point_id }
      loc && loc['libraryId']
    end

    # Check if valid service point
    def valid_service_point_code?(service_point_code)
      service_points.values.any? { |v| v.code == service_point_code }
    end

    # Given a library code, retrieve the primary service point, ensuring pickup location is true
    def map_to_service_point_code(library_code)
      # Find library id for the library with this code
      library_id = library_id(library_code)
      # Get the associated location and related service point
      service_point_id = service_point_for_library(library_id)
      # Find the service point ID based on this service point code
      service_point = service_point_by_id(service_point_id)
      service_point.present? && service_point.pickup_location == true ? service_point.code : nil
    end

    def library_id(library_code)
      lib = get_type('libraries').find { |library| library['code'] == library_code }
      lib.present? && lib.key?('id') ? lib['id'] : nil
    end

    def service_point_for_library(library_id)
      loc = get_type('locations').find { |location| location['libraryId'] == library_id }
      loc && loc['primaryServicePoint']
    end

    def service_point_by_id(service_point_id)
      service_points.values.find { |v| v.id == service_point_id }
    end

    # Get the name for the service point given the code
    def service_point_name(code)
      # Find the service point with the same code, and return the name
      service_points.values.find { |v| v.code == code }&.name
    end

    private

    # rubocop:disable Metrics/MethodLength
    def types_of_interest
      %w[
        request_policies
        loan_policies
        overdue_fines_policies
        lost_item_fees_policies
        patron_notice_policies
        patron_groups
        material_types
        loan_types
        institutions
        campuses
        libraries
        locations
        service_points
      ]
    end
    # rubocop:enable Metrics/MethodLength
  end
end
