# frozen_string_literal: true

module Folio
  # Account is FOLIO's model for tracking a sequence of payments/events for a fee/fine
  # Each account has a sequence of actions, stored as FeeFineActions
  # The account payment status is the status of the last action
  # https://wiki.folio.org/pages/viewpage.action?pageId=73531762
  class Account
    attr_reader :record

    # A sufficiently large time used to sort nil values last
    END_OF_DAYS = 100.years.from_now # rubocop:disable Rails/RelativeDateConstant

    delegate :library_name,
             :library_code,
             :from_ill?,
             :location,
             :effective_location,
             :permanent_location,
             to: :record_location

    # Statuses that indicate that the patron actually didn't pay anything
    UNPAID_STATUSES = ['Waived fully', 'Cancelled as error'].freeze

    def initialize(record)
      @record = record
    end

    def key
      record['id']
    end

    def patron_key
      record.dig('loan', 'proxyUserId') || record['userId']
    end

    def status
      record.dig('paymentStatus', 'name')
    end

    def nice_status
      record.dig('feeFine', 'feeFineType')
    end

    # dateCreated on the account is often null, so we often fall back on the first action date
    def bill_date
      @bill_date ||= begin
        value = record['dateCreated'] || record.dig('metadata', 'createdDate') || record.dig('actions', 0, 'dateAction')

        Time.zone.parse(value) if value
      end
    end

    def sort_date = bill_date

    def status_label
      nice_status.ends_with?('fee') ? nice_status : "#{nice_status} fee"
    end

    # dateUpdated on the account is often null, so we use the last action date if closed
    def payment_date
      return if record['actions'].none? || !closed?

      Time.zone.parse(record.dig('actions', -1, 'dateAction'))
    end

    def owed
      record['remaining']&.to_d
    end

    def fee
      record['amount']&.to_d
    end

    def bib?
      record['item'].present?
    end

    def catkey
      record.dig('item', 'instance', 'hrid')
    end

    def shelf_key
      record.dig('item', 'effectiveShelvingOrder')
    end

    def author
      record.dig('item', 'instance', 'contributors')&.pluck('name')&.join(', ')
    end

    def title
      record.dig('item', 'instance', 'title')
    end

    def call_number
      record.dig('item', 'holdingsRecord', 'callNumber')
    end

    def barcode
      record.dig('item', 'barcode')
    end

    def closed?
      record.dig('status', 'name') == 'Closed'
    end

    def sort_key(key)
      sort_key = case key
                 when :payment_date
                   [payment_sort_key, title, nice_status]
                 when :title
                   [title, payment_sort_key, nice_status]
                 when :fee
                   [fee, payment_sort_key, title, nice_status]
                 when :nice_status
                   [nice_status, payment_sort_key, title]
                 end

      sort_key.join('---')
    end

    def payment_sort_key
      return Folio::Account::END_OF_DAYS - payment_date if payment_date

      0
    end

    # 0 if the account was waived/cancelled; full amount otherwise — no partial payments
    # FOLIO treats waived/cancelled as though you paid, so we can't use 'remaining'
    def payment_amount
      UNPAID_STATUSES.include?(status) ? 0 : fee
    end

    delegate :contact_info, to: :location

    private

    def record_location
      @record_location ||= Folio::RecordLocation.new(record['item'] || {})
    end
  end
end
