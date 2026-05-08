# frozen_string_literal: true

module Cybersource
  # Request sent to Cybersource to initiate an external checkout
  # See the PDF linked in the README for more information on the fields
  class PaymentRequest
    include Enumerable

    attr_reader :user_id, :amount, :signature, :signed_date_time

    # Set of fields we use to generate the signature and that Cybersource verifies
    REQUEST_SIGNED_FIELDS = %i[access_key profile_id transaction_uuid signed_date_time
                               locale transaction_type reference_number amount currency
                               merchant_defined_data1 merchant_defined_data2 merchant_defined_data3
                               merchant_defined_data4 merchant_defined_data5
                               unsigned_field_names signed_field_names].freeze

    def initialize(user_id:, amount:, fine_ids:)
      @user_id = user_id
      @amount = amount
      @fine_ids = fine_ids
      @signed_fields = REQUEST_SIGNED_FIELDS
      @unsigned_fields = []
      @signed_date_time, @signature = nil
    end

    # Hash form including all data and signature
    def to_h
      signed_data.merge(unsigned_data).merge(signature: @signature)
    end

    # Support iterating keys and values for rendering as hidden form fields
    def each(&)
      to_h.each(&)
    end

    # Generate a security signature for the data and add a timestamp
    def sign!
      @signed_date_time = Time.now.utc.strftime('%Y-%m-%dT%H:%M:%SZ')
      @signature = Cybersource::Security.generate_signature(signed_data)

      self
    end

    def validate!
      Cybersource::Security.validate_signature!(@signature, signed_data)

      self
    end

    def signed?
      @signature.present?
    end

    def valid?
      Cybersource::Security.valid_signature?(@signature, signed_data)
    end

    private

    # Comma-separated parameter version of signed_fields
    def signed_field_names
      @signed_fields.join(',')
    end

    # Comma-separated parameter version of unsigned_fields
    def unsigned_field_names
      @unsigned_fields.join(',')
    end

    # Hash of signed fields and their values
    def signed_data
      @signed_data ||= @signed_fields.index_with { |field| send(field) }
    end

    # Hash of unsigned fields and their values
    def unsigned_data
      @unsigned_data ||= @unsigned_fields.index_with { |field| send(field) }
    end

    # Each transaction must have a unique ID
    def transaction_uuid
      @transaction_uuid ||= SecureRandom.uuid
    end

    # Passed back to us by Cybersource and used to look up the user in the ILS
    def reference_number
      @user_id
    end

    # Matches us with configuration on the Cybersource side; differs for dev/test/prod
    def access_key
      Settings.cybersource.access_key
    end

    # Identifies us as a "merchant" to Cybersource; one value for SUL as a whole
    def profile_id
      Settings.cybersource.profile_id
    end

    # Concatenation of truncated FOLIO UUIDs for accounts (fines) being paid.
    # These fields can store a colon-separated list of characters.
    # Each merchant_defined_data field can hold up to 100 characters so
    # we split them into 5 fields with a maximum of 12 charachers each,
    # The first 7 uuid characters plus a seperator yields 8 * 12 = 96 characters
    # per merchant_defined_data field.

    # Even if the number of payments made measn that we will not use all
    # of the merchant_defined_data fields, we still need to submit them
    # as empty, otherwise the payment form will not pass validation
    # (see above REQUEST_SIGNED_FIELDS list)

    # The merchant_defined_data fields show up in the reporting tool
    # provided by CyberSource, and we need to support tying
    # payments back to individual FOLIO account entries, not just the user.
    #
    # Since reporting is done on a per-month basis, the assumption is that
    # using a truncated form of the UUID is OK since collisions are unlikely.
    #
    # Based on an anaysis of payment that have been made so far, it is very unlikely that
    # there will be more that 60 fee/fine payments madd in a single transaction.
    #
    # See: https://github.com/sul-dlss/mylibrary/issues/1215
    def merchant_defined_data1
      @fine_ids[0, 12]&.pluck(0...7)&.join(':')
    end

    def merchant_defined_data2
      @fine_ids[12, 12]&.pluck(0...7)&.join(':')
    end

    def merchant_defined_data3
      @fine_ids[24, 12]&.pluck(0...7)&.join(':')
    end

    def merchant_defined_data4
      @fine_ids[36, 12]&.pluck(0...7)&.join(':')
    end

    def merchant_defined_data5
      @fine_ids[48, 12]&.pluck(0...7)&.join(':')
    end

    def transaction_type
      'sale'
    end

    def locale
      'en'
    end

    def currency
      'USD'
    end
  end
end
