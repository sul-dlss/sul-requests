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

    def initialize(user_info = nil, extended_user_info: nil, patron_graphql_response: nil)
      @user_info = user_info || extended_user_info || patron_graphql_response&.dig('user') || {}
      @extended_user_info = extended_user_info || patron_graphql_response&.dig('user')
      @patron_graphql_response = patron_graphql_response
    end

    def id
      user_info.fetch('id')
    end

    # TODO: mylibrary uses key instead of id for some reason.
    alias key id

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

    def fee_borrower?
      patron_group_name&.match?(/Fee borrower/i)
    end

    def borrow_limit
      borrow_limit = extended_user_info&.dig('patronGroup', 'limits')&.find do |limit|
        limit.dig('condition', 'name') == 'Maximum number of items charged out'
      end
      borrow_limit&.dig('value')
    end

    def remaining_checkouts
      return unless borrow_limit

      borrow_limit - checkouts.length
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

    def proxy?
      sponsors.any?
    end

    def sponsor?
      proxies.any?
    end

    # Return list of proxies that can act as behalf of this patron
    def proxies
      # Return display name for any proxies where 'requestForSponser' is yes.
      @proxies ||= Folio::PatronFinders.new(proxies_of_response.filter_map do |info|
        self.class.new(info['proxyUser']) if info['proxyUser'].present? && valid_proxy_relation?(info)
      end)
    end

    # Return list of sponsors this patron acts as a proxy for
    def sponsors
      # Return display name for any proxies where 'requestForSponser' is yes.
      @sponsors ||= Folio::PatronFinders.new(sponsors_for_response.filter_map do |info|
        self.class.new(info['user']) if info['user'].present? && valid_proxy_relation?(info)
      end)
    end

    def proxy_group
      @proxy_group ||= Folio::ProxyGroup.new(self)
    end

    def status
      standing
    end

    def standing
      if blocked?
        'Blocked'
      elsif barred?
        'Contact us'
      elsif expired?
        'Expired'
      else
        'OK'
      end
    end

    def barred?
      extended_user_info['manualBlocks'].any?
    end

    def blocked?
      patron_blocks.present?
    end

    def expired?
      user_info['active'] == false
    end

    def expired_date
      Time.zone.parse(user_info['expirationDate']) if user_info['expirationDate']
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

    def proxy_user(proxy_id)
      proxies.find { |proxy| proxy.id == proxy_id }
    end

    # Generate a PIN reset token for the patron
    def pin_reset_token
      crypt.encrypt_and_sign(id, expires_in: 20.minutes)
    end

    ##
    # FOLIO data accessors
    def all_accounts
      @all_accounts ||= (patron_graphql_response['accounts'] || []).map { |account| Account.new(account) }
    end

    def fines
      all_accounts.reject(&:closed?)
    end

    def payments
      all_accounts.select(&:closed?)
    end

    def all_checkouts
      @all_checkouts ||= (patron_graphql_response['loans'] || []).map { |checkout| Checkout.new(checkout, patron_group_id) }
    end

    # Self checkouts
    def checkouts
      all_checkouts.reject(&:proxy_checkout?)
    end

    # this is all requests including self and group/proxy
    def folio_requests
      (patron_graphql_response['holds'] || []).map { |request| Request.new(request) }
    end

    # Self requests from FOLIO
    def requests
      @requests ||= folio_requests.reject(&:proxy_request?)
    end

    # ILLIAD requests are retrieved separately
    def illiad_requests
      return [] unless username

      IlliadRequests.new(username).requests
    end

    ##
    # Business logic about what a patron can do.
    # TODO: move these checks to folio_abilities?
    def can_renew?
      return false if barred? || blocked? || expired?

      true
    end

    def can_modify_requests?
      return false if barred? || blocked? || expired?

      true
    end

    def can_pay_fines?
      return false if barred?

      true
    end

    private

    def extended_user_info
      @extended_user_info ||= folio_client.extended_user_info(id)
    end

    def patron_graphql_response
      @patron_graphql_response ||= folio_client.extended_patron_info(id) || {}
    end

    def valid_proxy_relation?(info)
      return false unless info['requestForSponsor']&.downcase == 'yes'
      return false if info['expirationDate'].present? && Time.zone.parse(info['expirationDate']).past?
      return false if info['status'] != 'Active'

      true
    end

    def patron_group_id
      # FOLIO APIs return a UUID here
      user_info['patronGroup'] || extended_user_info&.dig('patronGroup', 'id')
    end

    # Get all the sponsors for this patron
    def sponsors_for_response
      @sponsors_for_response ||= user_info.dig('stubs', 'sponsors') # used for stubbing
      @sponsors_for_response ||= extended_user_info&.dig('proxiesFor')
      @sponsors_for_response ||= []
    end

    # Get all the proxies of this patron
    def proxies_of_response
      @proxies_of_response ||= user_info.dig('stubs', 'proxies') # used for stubbing
      @proxies_of_response ||= extended_user_info&.dig('proxiesOf')
      @proxies_of_response ||= []
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
