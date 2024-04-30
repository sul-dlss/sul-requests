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

    def user
      @user ||= User.find_by(sunetid: username) ||
                User.find_by(library_id: university_id) ||
                User.find_by(library_id: barcode) ||
                User.create(sunetid: username, library_id: unversity_id, name: display_name, email:)
    end

    def id
      user_info.fetch('id')
    end

    def username
      user_info.fetch('username')
    end

    def patron_group_id
      # FOLIO APIs return a UUID here
      user_info.fetch('patronGroup')
    end

    # this returns the full patronGroup object
    def patron_group
      Folio::Types.patron_groups[patron_group_id]
    end

    def patron_group_name
      patron_group&.dig('group')
    end

    # always nil for a real patron, but filled in for a PseudoPatron
    def patron_comments; end

    # TODO: I belive we added this for parity with Symphony::Patron, but I don't think we will need it.
    # @deprecated
    def barcode
      user_info['barcode']
    end

    def fee_borrower?
      patron_group_name == 'sul-purchased'
    end

    def ilb_eligible?
      Settings.folio.ilb_eligible_patron_groups.include?(patron_group_name)
    end

    def make_request_as_patron?
      !expired? && patron_group_id.present?
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

    def proxy_email_address
      proxy_info&.dig('notificationsTo') || email
    end

    def proxy?
      proxy_info.present?
    end

    def sponsor?
      proxy_group_info.present?
    end

    # Return list of names of individuals who are proxies for this id
    def proxy_group_names
      # Return display name for any proxies where 'requestForSponser' is yes.
      @proxy_group_names ||= all_proxy_group_info.filter_map do |info|
        return nil unless info['requestForSponsor'].downcase == 'yes'

        # Find the patron corresponding to the Folio user id for the proxy
        proxy_patron = self.class.folio_client.find_patron_by_id(info['proxyUserId'])
        # If we find the corresponding FOLIO patron for the proxy, return the display name
        (proxy_patron.present? && proxy_patron&.display_name) || nil
      end
    end

    def proxy_sponsor_user_id
      proxy_info&.dig('userId')
    end

    def university_id
      user_info['externalSystemId']
    end

    def blocked?
      patron_blocks.fetch('automatedPatronBlocks').present?
    end

    def block_reasons
      blocks = patron_blocks.fetch('automatedPatronBlocks', [])
      blocks.map { |block| block['message'].include?('fine') ? 'outstanding fines' : 'overdue items' }
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

    # Get all the proxies for this id, and not just the first one
    def all_proxy_group_info
      @all_proxy_group_info ||= self.class.folio_client.all_proxy_group_info(id)
    end

    def standing
      user_info.dig('standing', 'key')
    end

    def expired?
      user_info['active'] == false
    end

    def policy_service
      @policy_service ||= Folio::CirculationRules::PolicyService.new(patron_groups: [patron_group_id])
    end

    def patron_blocks
      @patron_blocks ||= self.class.folio_client.patron_blocks(id)
    end

    def proxy_info
      @proxy_info ||= self.class.folio_client.proxy_info(id)
    end

    def proxy_group_info
      @proxy_group_info ||= self.class.folio_client.proxy_group_info(id)
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
