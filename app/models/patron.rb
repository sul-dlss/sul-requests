# frozen_string_literal: true

# Class to model Patron information from Symphony Web Services
# Partially extracted from https://github.com/sul-dlss/mylibrary/blob/master/app/models/patron.rb
class Patron
  attr_reader :record

  def initialize(record)
    @record = record
  end

  def fields
    record['fields'] || {}
  end

  def profile_key
    fields.dig('profile', 'key')
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

  def group
    @group ||= Group.new(record)
  end
end
