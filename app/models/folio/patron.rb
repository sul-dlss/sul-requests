# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class Patron
    # rubocop:disable Metrics/CyclomaticComplexity
    def self.find_by(sunetid: nil, library_id: nil, **_kwargs)
      # if no sunet or library_id they are probably a general public (name/email) user.
      return unless sunetid || library_id.present?

      response = folio_client.login_by_sunetid(sunetid) if sunetid.present?
      response ||= folio_client.login_by_library_id(library_id) if library_id.present?

      return new(response) if response.present?

      Honeybadger.notify("Unable to find patron (looked up by sunetid: #{sunetid} / barcode: #{library_id}")

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

    # always nil for a real patron, but filled in for a PseudoPatron
    def patron_comments; end

    # TODO: I belive we added this for parity with Symphony::Patron, but I don't think we will need it.
    # @deprecated
    def barcode
      user_info['barcode']
    end

    def fee_borrower?
      user_info.fetch('patronGroup') == Settings.folio.fee_borrower_patron_group
    end

    def standing
      user_info.dig('standing', 'key')
    end

    def good_standing?
      user_info['active'] && !blocked?
    end

    def first_name
      field.dig('personal', 'preferredFirstName') || user_info.dig('personal', 'firstName')
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
      !user_info['active']
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
