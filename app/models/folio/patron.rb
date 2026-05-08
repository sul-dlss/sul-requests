# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class Patron
    def self.find_by(sunetid: nil, library_id: nil, patron_key: nil, **_kwargs) # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      user_info = folio_client.find_user_by_id(patron_key) if patron_key.present?
      user_info ||= folio_client.find_user_by_barcode(library_id) if library_id.present?
      user_info ||= folio_client.find_user_by_university_id(library_id) if library_id.present?
      user_info ||= folio_client.find_user_by_legacy_barcode(library_id) if library_id.present?
      user_info ||= folio_client.find_user_by_sunetid(sunetid) if sunetid.present?

      Folio::Patron.new(user_info) if user_info
    rescue ActiveRecord::RecordNotFound
      Honeybadger.notify("Unable to find patron using sunetid: #{sunetid}, library_id: #{library_id}, patron_key: #{patron_key}")
      nil
    rescue HTTP::Error, FolioClient::Error
      nil
    end

    def self.folio_client
      FolioClient.new
    end

    attr_reader :user_info

    delegate :folio_client, to: :class

    def initialize(user_info = {})
      @user_info = user_info
    end

    def id
      user_info.fetch('id')
    end

    def username
      user_info['username']
    end

    def personal_data
      user_info['personal'] || {}
    end

    def first_name
      personal_data['preferredFirstName'] || personal_data['firstName']
    end

    def last_name
      personal_data['lastName']
    end

    def display_name
      [first_name, last_name].join(' ')
    end

    def email
      personal_data['email']
    end

    def primary_address
      personal_data['addresses']&.find { |address| address['primaryAddress'] } || personal_data['addresses']&.first || {}
    end

    def library_id
      university_id || barcode
    end

    # TODO: I belive we added this for parity with Symphony::Patron, but I don't think we will need it.
    # @deprecated
    def barcode
      user_info['barcode']
    end

    def university_id
      user_info['externalSystemId']
    end

    # this returns the full patronGroup object
    def patron_group # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/PerceivedComplexity
      @patron_group ||= Folio::NullPatron.visitor_patron_group if expired?
      @patron_group ||= Folio::Types.patron_groups.find_by(id: patron_group_id) if patron_group_id

      @patron_group ||= if extended_user_info&.dig('patronGroup').present?
                          Folio::PatronGroup.from_dynamic(extended_user_info&.dig('patronGroup'))
                        end

      @patron_group ||= Folio::NullPatron.visitor_patron_group
    end

    def patron_group_name
      patron_group&.group
    end

    # always nil for a real patron, but filled in for a PseudoPatron
    def patron_comments; end

    def ilb_eligible?
      username && Settings.folio.ilb_eligible_patron_groups.include?(patron_group_name) && !expired?
    end

    def make_request_as_patron?
      !expired? && patron_group.present?
    end

    def patron_description
      patron_group.desc
    end

    # @deprecated
    def proxy_email_address
      sponsors&.first&.notifications_to || email
    end

    # @deprecated
    def notifications_to
      user_info['notificationsTo']
    end

    def proxy?
      sponsors.any?
    end

    def sponsor?
      proxies.any?
    end

    # Return list of proxies that can act as behalf of this patron
    def proxies
      # Return display name for any proxies where 'requestForSponser' is yes.
      @proxies ||= proxies_of_response.filter_map do |info|
        next nil unless valid_proxy_relation?(info)

        self.class.new(info['proxyUser']) if info['proxyUser'].present?
      end
    end

    # Return list of sponsors this patron acts as a proxy for
    def sponsors
      # Return display name for any proxies where 'requestForSponser' is yes.
      @sponsors ||= sponsors_for_response.filter_map do |info|
        next nil unless valid_proxy_relation?(info)

        self.class.new(info['user']) if info['user'].present?
      end
    end

    # @deprecated
    def proxy_sponsor_user_id
      sponsors.first.id
    end

    def blocked?
      patron_blocks.present?
    end

    def expired?
      user_info['active'] == false
    end

    def block_reasons
      patron_blocks.map { |block| block['message'].include?('fine') ? 'outstanding fines' : 'overdue items' }
    end

    def fix_block_message
      block_reasons.map { |br| br == 'outstanding fines' ? 'the fines are cleared' : 'the overdue items are returned' }.join(' and ')
    end

    def exists?
      user_info.present?
    end

    def allowed_request_types(item)
      policy_service.item_request_policy(item)&.dig('requestTypes') || []
    end

    # Generate a PIN reset token for the patron
    def pin_reset_token
      crypt.encrypt_and_sign(id, expires_in: 20.minutes)
    end

    private

    def extended_user_info
      @extended_user_info ||= folio_client.extended_user_info(id)
    end

    def valid_proxy_relation?(info)
      return false unless info['requestForSponsor']&.downcase == 'yes'
      return false if info['expirationDate'].present? && Time.zone.parse(info['expirationDate']).past?
      return false if info['status'] != 'Active'

      true
    end

    def patron_group_id
      # FOLIO APIs return a UUID here
      user_info['patronGroup']
    end

    # Get all the sponsors for this patron
    def sponsors_for_response
      @sponsors_for_response ||= user_info.dig('stubs', 'sponsors') # used for stubbing
      @sponsors_for_response ||= extended_user_info&.dig('proxiesFor')
    end

    # Get all the proxies of this patron
    def proxies_of_response
      @proxies_of_response ||= user_info.dig('stubs', 'proxies') # used for stubbing
      @proxies_of_response ||= extended_user_info&.dig('proxiesOf')
    end

    def standing
      user_info.dig('standing', 'key')
    end

    def policy_service
      @policy_service ||= Folio::CirculationRules::PolicyService.new(patron_groups: [patron_group.id])
    end

    def patron_blocks
      @patron_blocks ||= user_info.dig('stubs', 'patron_blocks') # used for stubbing
      @patron_blocks ||= extended_user_info&.dig('blocks')
    end

    # Encryptor/decryptor for the token used in the PIN reset process
    def crypt
      @crypt ||= begin
        keygen = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base)
        key = keygen.generate_key('patron pin reset token', ActiveSupport::MessageEncryptor.key_len)
        ActiveSupport::MessageEncryptor.new(key)
      end
    end
  end
end
