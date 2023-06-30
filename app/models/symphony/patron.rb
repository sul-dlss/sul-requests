# frozen_string_literal: true

module Symphony
  # Class to model Patron information from Symphony Web Services
  # Partially extracted from https://github.com/sul-dlss/mylibrary/blob/master/app/models/patron.rb
  class Patron < Symphony::Base
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize
    def self.find_by(sunetid: nil, library_id: nil, patron_key: nil, with_holds: false)
      patron_key ||= symphony_client.login_by_sunetid(sunetid)&.dig('key') if sunetid.present?
      patron_key ||= symphony_client.login_by_library_id(library_id)&.dig('key') if library_id.present?

      return new(symphony_client.patron_info(patron_key, return_holds: with_holds)) if patron_key.present?

      # if no sunet or library_id they are probably a general public (name/email) user. We don't want that case logged.
      if sunetid || library_id.present?
        Honeybadger.notify("Unable to find patron (looked up by sunetid: #{sunetid} / barcode: #{library_id}")
      end

      nil
    rescue HTTP::Error
      nil
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/AbcSize

    def barcode
      fields['barcode']
    end

    def anonymized_id
      if barcode
        "xxxx#{barcode.slice(-6..-1)}"
      else
        "id #{key}"
      end
    end

    def profile_key
      fields.dig('profile', 'key')
    end

    def holds
      @holds ||= begin
        records = hold_record_list || Symphony::Patron.find_by(patron_key: key, with_holds: true)&.hold_record_list || []

        records.map { |record| Symphony::HoldRecord.new(record) }
      end
    end

    def hold_record_list
      fields.dig('holdRecordList')
    end

    def fee_borrower?
      profile_key&.starts_with?('MXFEE')
    end

    def standing
      fields.dig('standing', 'key')
    end

    def good_standing?
      ['DELINQUENT', 'OK'].include?(standing) && !expired?
    end

    def first_name
      fields['firstName']
    end

    def last_name
      fields['lastName']
    end

    def display_name
      [first_name, last_name].join(' ')
    end

    def email
      email_resource = fields.dig('address1').find do |address|
        address['fields']['code']['key'] == 'EMAIL'
      end
      email_resource && email_resource['fields']['data']
    end

    def expired?
      return false unless expired_date

      expired_date.past?
    end

    def expired_date
      Time.zone.parse(fields['privilegeExpiresDate']) if fields['privilegeExpiresDate']
    end

    def proxy?
      fields.dig('groupSettings', 'fields', 'responsibility', 'key') == 'PROXY'
    end

    def sponsor?
      fields.dig('groupSettings', 'fields', 'responsibility', 'key') == 'SPONSOR'
    end

    def checkouts
      @checkouts ||= symphony_client.checkouts(key).map { |record| Symphony::CircRecord.new(record) }
    end

    def group
      @group ||= Symphony::Group.new(response)
    end

    def university_id
      fields['alternateID']
    end
  end
end
