# frozen_string_literal: true

module Folio
  # This class is responsible for loading the types from the FOLIO API and
  # caching them locally. It also provides some convenience methods for
  # accessing the types.
  class Types
    class << self
      delegate :policies, :circulation_rules, :criteria, :get_type, to: :instance
    end

    def self.instance
      @instance ||= new
    end

    attr_reader :cache_dir, :folio_client

    def initialize(cache_dir: Rails.root.join('config/folio'), folio_client: FolioClient.new)
      @cache_dir = cache_dir
      @folio_client = folio_client
    end

    def sync!
      types_of_interest.each do |type|
        file = cache_dir.join("#{type}.json")

        File.write(file, JSON.pretty_generate(folio_client.public_send(type)))
      end
    end

    def circulation_rules
      get_type('circulation_rules').fetch('rulesAsText', '')
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
        'location-library' => get_type('libraries').index_by { |p| p['id'] },
        'location-location' => get_type('locations').index_by { |p| p['id'] }
      }
    end
    # rubocop:enable Metrics/AbcSize

    def get_type(type)
      raise "Unknown type #{type}" unless types_of_interest.include?(type.to_s)

      file = cache_dir.join("#{type}.json")
      JSON.parse(file.read) if file.exist?
    end

    private

    def types_of_interest
      %w[
        request_policies loan_policies overdue_fines_policies lost_item_fees_policies patron_notice_policies
        patron_groups material_types loan_types institutions campuses libraries locations service_points
        circulation_rules
      ]
    end
  end
end
