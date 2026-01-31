# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class Patron
    def self.find_by(sunetid: nil, library_id: nil, patron_key: nil, **_kwargs)
      return folio_client.find_patron_by_id(patron_key) if patron_key.present?
      return folio_client.find_patron_by_barcode_or_university_id(library_id) if library_id.present?
      return folio_client.find_patron_by_sunetid(sunetid) if sunetid.present?

      nil
    rescue HTTP::Error
      nil
    end

    def self.folio_client
      FolioClient.new
    end

    attr_reader :user_info

    def initialize(fields = {})
      @user_info = fields
    end

    def id
      user_info.fetch('id')
    end

    def username
      user_info['username']
    end

    # this returns the full patronGroup object
    def patron_group
      @patron_group ||= Folio::NullPatron.visitor_patron_group if expired?
      @patron_group ||= Folio::Types.patron_groups[patron_group_id] if patron_group_id
      @patron_group ||= Folio::NullPatron.visitor_patron_group
    end

    def patron_group_name
      patron_group&.dig('group')
    end

    # always nil for a real patron, but filled in for a PseudoPatron
    def patron_comments; end

    def library_id
      university_id || barcode
    end

    # TODO: I belive we added this for parity with Symphony::Patron, but I don't think we will need it.
    # @deprecated
    def barcode
      user_info['barcode']
    end

    def ilb_eligible?
      username && Settings.folio.ilb_eligible_patron_groups.include?(patron_group_name) && !expired?
    end

    def make_request_as_patron?
      !expired? && patron_group.present?
    end

    def first_name
      user_info.dig('personal', 'preferredFirstName') || user_info.dig('personal', 'firstName')
    end

    def last_name
      user_info.dig('personal', 'lastName')
    end

    def display_name
      [first_name, last_name].join(' ')
    end

    def email
      user_info.dig('personal', 'email')
    end

    def patron_description
      patron_group['desc']
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

        # Find the patron corresponding to the Folio user id for the proxy
        proxy_patron = self.class.find_by(patron_key: info['proxyUserId'])
        proxy_patron.presence
      end
    end

    # Return list of sponsors this patron acts as a proxy for
    def sponsors
      # Return display name for any proxies where 'requestForSponser' is yes.
      @sponsors ||= sponsors_for_response.filter_map do |info|
        next nil unless valid_proxy_relation?(info)

        # Find the patron corresponding to the Folio user id for the sponsor
        sponsor_patron = self.class.find_by(patron_key: info['userId'])
        sponsor_patron.presence
      end
    end

    def university_id
      user_info['externalSystemId']
    end

    # @deprecated
    def proxy_sponsor_user_id
      sponsors.first.id
    end

    def blocked?
      patron_blocks.present?
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

    def expired?
      user_info['active'] == false
    end

    private

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
      @sponsors_for_response ||= self.class.folio_client.proxies(proxyUserId: id)
    end

    # Get all the proxies of this patron
    def proxies_of_response
      @proxies_of_response ||= user_info.dig('stubs', 'proxies') # used for stubbing
      @proxies_of_response ||= self.class.folio_client.proxies(userId: id)
    end

    def standing
      user_info.dig('standing', 'key')
    end

    def policy_service
      @policy_service ||= Folio::CirculationRules::PolicyService.new(patron_groups: [patron_group['id']])
    end

    def patron_blocks
      @patron_blocks ||= user_info.dig('stubs', 'patron_blocks') # used for stubbing
      @patron_blocks ||= self.class.folio_client.patron_blocks(id).fetch('automatedPatronBlocks', [])
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
