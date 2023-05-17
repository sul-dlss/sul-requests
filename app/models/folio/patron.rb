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

    attr_reader :fields

    def initialize(fields = {})
      @fields = fields
    end

    def id
      fields['id']
    end

    def barcode
      fields['barcode']
    end

    # TODO
    def fee_borrower?
      false
    end

    def standing
      fields.dig('standing', 'key')
    end

    def good_standing?
      fields['active']
    end

    def first_name
      field.dig('personal', 'preferredFirstName') || fields.dig('personal', 'firstName')
    end

    def last_name
      fields.dig('personal', 'lastName')
    end

    def display_name
      [first_name, last_name].join(' ')
    end

    def email
      fields.dig('personal', 'email')
    end

    def expired?
      !fields['active']
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
      fields['externalSystemId']
    end
  end
end
