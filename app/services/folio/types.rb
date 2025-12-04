# frozen_string_literal: true

module Folio
  # This class is responsible for loading the types from the FOLIO API and
  # caching them locally. It also provides some convenience methods for
  # accessing the types.
  class Types
    class << self
      delegate  :policies, :circulation_rules, :criteria,
                :locations, :libraries, :campuses, :service_points, :patron_groups, to: :instance
    end

    def self.instance
      @instance ||= new
    end

    attr_reader :cache_dir, :folio_client

    def initialize(cache_dir: Rails.root.join('config/folio', Settings.folio.config_set), folio_client: FolioClient.new)
      @cache_dir = cache_dir
      @folio_client = folio_client
    end

    # rubocop:disable Metrics/AbcSize
    def sync!
      @policies = nil
      @criteria = nil

      types_of_interest.each do |type|
        file = cache_dir.join("#{type}.json")
        data = folio_client.public_send(type).sort_by { |item| item['id'] }
        File.write(file, JSON.pretty_generate(data))
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
      @service_points ||= ServicePointStore.new(get_type('service_points'))
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

    def patron_groups
      get_type('patron_groups').index_by { |p| p['id'] }
    end

    # rubocop:disable Metrics/AbcSize
    def criteria
      @criteria ||= {
        'group' => patron_groups,
        'material-type' => get_type('material_types').index_by { |p| p['id'] },
        'loan-type' => get_type('loan_types').index_by { |p| p['id'] },
        'location-institution' => get_type('institutions').index_by { |p| p['id'] },
        'location-campus' => get_type('campuses').index_by { |p| p['id'] },
        'location-library' => libraries.all.index_by(&:id).transform_values(&:to_h).transform_values(&:with_indifferent_access),
        'location-location' => locations.all.index_by(&:id).transform_values(&:to_h).transform_values(&:with_indifferent_access)
      }
    end
    # rubocop:enable Metrics/AbcSize

    def libraries
      @libraries ||= LibrariesStore.new(get_type('libraries'))
    end

    def locations
      @locations ||= LocationsStore.new(get_type('locations'))
    end

    def campuses
      @campuses ||= get_type('campuses').map do |c|
        Folio::Campus.new(**c.slice('id', 'code').symbolize_keys)
      end
    end

    def get_type(type)
      raise "Unknown type #{type}" unless types_of_interest.include?(type.to_s)

      file = cache_dir.join("#{type}.json")
      JSON.parse(file.read) if file.exist?
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
