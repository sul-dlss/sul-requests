# frozen_string_literal: true

# Class to model Patron information from Symphony Web Services
# Partially extracted from https://github.com/sul-dlss/mylibrary/blob/master/app/models/patron.rb
class Patron
  attr_reader :record

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
  def self.find_by(sunetid: nil, library_id: nil, patron_key: nil, symphony_client: SymphonyClient.new)
    patron_key ||= symphony_client.login_by_sunetid(sunetid)&.dig('key') if sunetid
    patron_key ||= symphony_client.login_by_library_id(library_id)&.dig('key') if library_id

    return new(symphony_client.patron_info(patron_key)) if patron_key.present?

    Honeybadger.notify("Unable to find patron (looked up by sunetid: #{sunetid} / barcode: #{library_id}")

    nil
  rescue HTTP::Error
    nil
  end
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

  def initialize(record)
    @record = record
  end

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

  def exists?
    fields.present?
  end

  def key
    record['key']
  end

  def fields
    record['fields'] || {}
  end

  def profile_key
    fields.dig('profile', 'key')
  end

  def holds
    @holds ||= (fields.dig('holdRecordList') || []).map { |record| HoldRecord.new(record) }
  end

  def fee_borrower?
    profile_key&.starts_with?('MXFEE')
  end

  def standing
    fields.dig('standing', 'key')
  end

  def good_standing?
    ['DELINQUENT', 'OK'].include?(standing)
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
    @checkouts ||= SymphonyClient.new.checkouts(key).map { |record| CircRecord.new(record) }
  end

  def group
    @group ||= Group.new(record)
  end
end
