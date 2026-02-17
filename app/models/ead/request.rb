# frozen_string_literal: true

module Ead
  ##
  # Model for EAD-based requests
  class Request
    attr_reader :user, :ead, :items, :request_data

    # Maps from the value in EAD to Aeon's valid site codes
    REPOSITORY_TO_SITE_CODE = {
      'Department of Special Collections and University Archives' => 'SPECUA',
      'Archive of Recorded Sound' => 'ARS',
      'East Asia Library' => 'EASTASIA'
    }.freeze

    delegate :title, :creator, :call_number, :identifier, :repository, :collection_permalink, to: :ead

    def initialize(user:, ead:, items: [], **request_data)
      @user = user
      @ead = ead
      @items = items
      @request_data = request_data
    end

    def create_aeon_requests!
      items.map do |volume|
        aeon_client.create_request(as_aeon_create_request_data(volume))
        { volume: volume, success: true }
      rescue StandardError => e
        { volume: volume, success: false, error: e.message }
      end
    end

    def site
      return nil unless repository

      # TODO: Fallback to SPECUA? Other logic?
      REPOSITORY_TO_SITE_CODE[repository] || 'SPECUA'
    end

    def reading_room
      @reading_room ||= aeon_client.reading_rooms.find { |rr| rr.sites.include?(site) }
    end

    private

    def as_aeon_create_request_data(volume) # rubocop:disable Metrics/MethodLength
      AeonClient::CreateRequestData.new(
        call_number: "#{identifier} #{volume['series']}",
        ead_number: identifier,
        item_author: creator,
        item_citation: nil,
        item_date: nil,
        item_info1: collection_permalink,
        item_info2: nil,
        item_info3: nil,
        item_info4: nil,
        item_info5: nil,
        item_subtitle: nil,
        item_title: title,
        item_volume: volume['subseries'],
        shipping_option: nil,
        site: site,
        special_request: nil,
        username: user.email_address,
        **request_data
      )
    end

    def aeon_client
      @aeon_client ||= AeonClient.new
    end
  end
end
