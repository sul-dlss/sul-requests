# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class Patron
    # rubocop:disable Metrics/CyclomaticComplexity
    def self.find_by(sunetid: nil, univ_id: nil, **_kwargs)
      # if no sunet or univ_id they are probably a general public (name/email) user.
      return unless sunetid || univ_id.present?

      response = folio_client.login_by_sunetid(sunetid) if sunetid.present?
      response ||= folio_client.login_by_university_id(univ_id) if univ_id.present?

      return new(response) if response.present?

      Honeybadger.notify("Unable to find patron (looked up by sunetid: #{sunetid} / university ID: #{univ_id}")

      nil
    rescue HTTP::Error
      nil
    end
    # rubocop:enable Metrics/CyclomaticComplexity

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

    def standing
      user_info.dig('standing', 'key')
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

    def proxy_email_address
      proxy_info&.dig('notificationsTo') || email
    end

    def expired?
      user_info['active'] == false
    end

    def proxy?
      proxy_info.present?
    end

    def sponsor?
      proxy_group_info.present?
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

    def exists?
      user_info.present?
    end

    private

    def patron_blocks
      @patron_blocks ||= self.class.folio_client.patron_blocks(id)
    end

    def proxy_info
      @proxy_info ||= self.class.folio_client.proxy_info(id)
    end

    def proxy_group_info
      @proxy_group_info ||= self.class.folio_client.proxy_group_info(id)
    end
  end
end
