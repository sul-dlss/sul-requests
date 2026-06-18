# frozen_string_literal: true

module Folio
  # ? FOLIO: Checkout = "Loan" in Folio - consider renaming for clarity
  class Checkout
    include Folio::FolioRecord
    include ActiveModel::Model

    attr_reader :record, :patron_type_id
    attr_writer :loan_policy

    delegate :loan_policy_interval,
             to: :loan_policy,
             private: true

    SHORT_TERM_LOAN_PERIODS = %w[Hours Minutes].freeze
    FOLIO_LOST_STATUSES = ['Aged to lost', 'Declared lost'].freeze

    def initialize(record, patron_type_id, loan_policy: nil)
      @record = record
      @patron_type_id = patron_type_id
      @loan_policy = loan_policy
    end

    def update(data = {})
      self.class.new(record.deep_merge(data), patron_type_id, loan_policy:)
    end

    def key
      record['id']
    end
    alias id key

    def bib?
      record['item'].present?
    end

    def status
      record.dig('details', 'status', 'name')
    end

    def due_date
      Time.zone.parse(record['dueDate'])
    end

    def sort_date = due_date

    def status_label = 'Item overdue'

    def days_overdue
      return 0 unless overdue?
      return 0 if due_date.nil?

      ((Time.zone.now - due_date).to_i / 60 / 60 / 24) + 1
    end

    def checkout_date
      Time.zone.parse(record['loanDate'])
    end

    def recalled?
      record.dig('details', 'dueDateChangedByRecall') || record.dig('details', 'dueDateChangedByHold')
    end

    def claims_returned_date
      claimed_returned? && Time.zone.parse(record.dig('item', 'item', 'status', 'date'))
    end

    def claimed_returned?
      record.dig('item', 'item', 'status', 'name') == 'Claimed returned'
    end

    def item_category_non_renewable?
      !loan_policy.renewable?
    end

    def renewable? # rubocop:disable Metrics/CyclomaticComplexity
      # The item is not renewable
      return false if reserve_item?

      # The item state doesn't allow renewals
      return false if lost? || recalled? || claimed_returned? || renewal_blocked_by_hold?

      # The loan policy for the patron + item doesn't allow renewals
      return false if item_category_non_renewable?

      # Renewing would not extend the due date
      return false if too_soon_to_renew?

      unseen_renewals_remaining.positive?
    end

    def patron_key
      record.dig('details', 'proxyUserId') || record.dig('details', 'userId')
    end

    # @return [Boolean] Returns true if the proxyUserId exists
    def proxy_checkout?
      record.dig('details', 'proxyUserId').present?
    end

    def overdue?
      record['overdue']
    end

    def accrued
      record.dig('details', 'feesAndFines', 'amountRemainingToPay') || 0.0
    end

    # TODO: verify this logic is correct
    def accruing?
      overdue? && overdue_fines_rate&.dig('quantity').to_f.positive?
    end

    def days_remaining
      return 0 if overdue?
      return -1 if due_date.nil?

      (due_date.to_date - Time.zone.now.to_date).to_i
    end

    def short_term_loan?
      SHORT_TERM_LOAN_PERIODS.include?(loan_policy_interval)
    end

    # rubocop:disable Metrics/MethodLength
    def sort_key(key)
      sort_key = case key
                 when :status
                   [status_sort_key, title, author, shelf_key]
                 when :due_date
                   [due_date_sort_value, title, author, shelf_key]
                 when :title
                   [title, author, shelf_key]
                 when :author
                   [author, title, shelf_key]
                 when :call_number
                   [shelf_key]
                 end

      sort_key.join('---')
    end

    def due_date_sort_value
      due_date&.strftime('%FT%T') || ''
    end

    def status_sort_key
      if recalled?
        0
      elsif lost?
        1
      elsif claimed_returned?
        4
      elsif accrued.positive?
        2
      elsif overdue?
        3
      else
        9
      end
    end
    # rubocop:enable Metrics/MethodLength

    def lost?
      FOLIO_LOST_STATUSES.include?(record.dig('item', 'item', 'status', 'name'))
    end

    def barcode
      record.dig('item', 'item', 'barcode')
    end

    def reserve_item?
      /reserves?/i.match?(loan_policy.description)
    end

    def renewal_count
      record.dig('details', 'renewalCount') || 0
    end

    # returns {"quantity" => 1.0, "intervalId" => "hour"}
    # TODO: verify this logic with Sarah
    # There was talk of the 'overdueRecallFine' being relvant in addition to 'overdueFine'
    # if relevant, both would need to be checked, but they have the same structure of {"quantity" => 1.0, "intervalId" => "hour"}
    def overdue_fines_rate
      overdue_fines_policy['overdueFine']
    end

    def contact_info
      location&.contact_info
    end

    def too_soon_to_renew?
      loan_policy.too_soon_to_renew?(due_date)
    end

    def renewal_blocked_by_hold?
      hold_queue_length.positive? && !loan_policy.renewals_allowed_with_open_holds?
    end

    def unseen_renewals_remaining
      (loan_policy.unseen_renewals_allowed - renewal_count)
    end

    private

    def loan_policy
      @loan_policy ||= Folio::LoanPolicy.new(loan_policy: effective_loan_policy)
    end

    def effective_loan_policy
      @effective_loan_policy ||= Folio::Types.policies[:loan].fetch(effective_loan_policy_id) do
        Honeybadger.notify('Unable to find loan policy for checkout',
                           context: { key:, effective_loan_policy_id: })
        {}
      end
    end

    # NOTE: We need to fetch the latest loan policy to evaluate renewability. The loan policy returned
    # with the loan is the policy at the time of checkout and could have changed in ways that impact
    # eligibility for renewal.
    def effective_loan_policy_id # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      cache_key = ['effective_loan_policy_id', item_type_id, loan_type_id, patron_type_id, effective_location_id].join(':')
      Rails.cache.fetch(cache_key, expires_in: 1.day) do
        response = FolioClient.new.find_effective_loan_policy(item_type_id:,
                                                              loan_type_id:,
                                                              patron_type_id:,
                                                              location_id: effective_location_id)

        unless response['loanPolicyId']
          Honeybadger.notify('Unable to find effective loan policy for checkout',
                             context: { key:, cache_key:, response: })
        end

        response['loanPolicyId']
      end
    end

    def overdue_fines_policy
      @overdue_fines_policy ||= Folio::Types.policies[:overdue].fetch(overdue_fines_policy_id) do
        Honeybadger.notify('Unable to find overdue fines policy for checkout',
                           context: { key:, overdue_fines_policy_id: })
        {}
      end
    end

    def overdue_fines_policy_id # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      cache_key = ['overdue_fines_policy_id', item_type_id, loan_type_id, loan_type_id, effective_location_id].join(':')
      Rails.cache.fetch(cache_key, expires_in: 1.day) do
        response = FolioClient.new.find_overdue_fines_policy(item_type_id:,
                                                             loan_type_id:,
                                                             patron_type_id:,
                                                             location_id: effective_location_id)

        unless response&.dig('overdueFinePolicyId')
          Honeybadger.notify('Unable to find overdue fines policy for checkout',
                             context: { key:, cache_key:, response: })
        end

        response&.dig('overdueFinePolicyId')
      end
    end

    def loan_type_id
      record.dig('item', 'item', 'temporaryLoanTypeId') ||
        record.dig('item', 'item', 'permanentLoanTypeId')
    end

    def item_type_id
      record.dig('item', 'item', 'materialTypeId')
    end

    def hold_queue_length
      record.dig('item', 'item', 'queueTotalLength') || 0
    end
  end
end
