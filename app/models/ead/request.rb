# frozen_string_literal: true

module Ead
  ##
  # Model for EAD-based requests
  class Request
    include ActiveModel::Model

    attr_reader :user, :ead, :params, :reference_number

    # Maps from the value in EAD to Aeon's valid site codes
    REPOSITORY_TO_SITE_CODE = {
      'Department of Special Collections and University Archives' => 'SPECUA',
      'Archive of Recorded Sound' => 'ARS',
      'East Asia Library' => 'EASTASIA'
    }.freeze

    delegate :title, :creator, :call_number, :identifier, :repository, :collection_permalink, :url, to: :ead

    def initialize(user:, ead:, params: {}, reference_number: nil)
      @user = user
      @ead = ead
      @params = params
      @reference_number = reference_number
    end

    def appointments
      @appointments ||= user.aeon.appointments.select { |appt| appt.reading_room.sites.include?(site) }
    end

    def create_aeon_requests!
      params[:items].map do |volume_params|
        aeon_client.create_request(as_aeon_create_request_data(volume_params))
        { volume: volume_params, success: true }
      rescue StandardError => e
        { volume: volume_params, success: false, error: e.message }
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

    def request_type
      params[:request_type]
    end

    def items
      params[:items] || []
    end

    private

    def as_aeon_create_request_data(volume_params) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      AeonClient::CreateRequestData.with_defaults.with(
        call_number: "#{identifier} #{volume_params['series']}",
        ead_number: identifier,
        for_publication: volume_params['for_publication'] == 'yes',
        item_author: creator,
        item_info1: collection_permalink,
        item_info5: volume_params['requested_pages'],
        item_title: title,
        item_volume: volume_params['subseries'],
        reference_number: reference_number,
        shipping_option: params[:request_type] == 'scan' ? 'Electronic Delivery' : nil,
        site: site,
        special_request: volume_params['additional_information'],
        username: user.email_address
      )
    end

    def aeon_client
      @aeon_client ||= AeonClient.new
    end
  end
end
