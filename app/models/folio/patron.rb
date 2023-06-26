# frozen_string_literal: true

module Folio
  # Model for working with FOLIO Patron information
  class Patron
    def self.find_by(sunetid: nil, library_id: nil, **_kwargs)
      return new(folio_client.login_by_sunetid(sunetid)) if sunetid.present?
      return new(folio_client.login_by_library_id(library_id)) if library_id.present?

      Honeybadger.notify("Unable to find patron (looked up by sunetid: #{sunetid} / barcode: #{library_id}")

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
      user_info['id']
    end

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
      user_info['active']
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

    def expired?
      !user_info['active']
    end

    # TODO
    def proxy?
      false
    end

    # TODO
    def sponsor?
      false
    end

    # TODO
    def group
      nil
    end

    def university_id
      user_info['externalSystemId']
    end
  end
end
