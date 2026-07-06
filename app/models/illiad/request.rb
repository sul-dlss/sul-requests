# frozen_string_literal: true

###
#  Class to handle creation of ILLiad OpenURL request
###
module Illiad
  # ILLiad Request class (that duck-types our Folio::Request class)
  class Request
    def self.where(user_id:)
      IlliadClient.new.user_transactions(user_id).map { |illiad_result| Illiad::Request.new(illiad_result) }.reject(&:inactive?)
    end

    include ActiveModel::Model

    INACTIVE_REQUEST_STATUSES = [
      'Awaiting Renewal OK Processing', 'Awaiting Renewal Request Processing', 'Awaiting Return Label Printing',
      'Borrow Direct Loan from an Ivy+ Library', 'Borrow Direct Lost', 'Borrow Direct Testing',
      'Checked Out to Customer', 'Claims Returned', 'In Return Address Print Queue',
      'In Transit from Customer', 'Loaned from UC Berkeley RLCP', 'Lost',
      'Returned to Borrow Direct Ivy+ Library', 'Returned UC Berkeley RLCP', 'Cancelled by Customer',
      'Cancelled by ILL Staff', 'Delivered to Web', 'Request Finished',
      'Awaiting Denied Renewal Processing', 'In Transit to Pickup Location', 'Awaiting Doc Del Customer Contact'
    ].freeze

    # illiad_result is a hash with the results from the Illiad Request
    def initialize(illiad_result)
      @illiad_result = illiad_result
    end

    def inactive?
      INACTIVE_REQUEST_STATUSES.include? @illiad_result['TransactionStatus']
    end

    def scan_type?
      @illiad_result['PhotoJournalTitle'].present?
    end

    def key
      @illiad_result['TransactionNumber'].to_s
    end
    alias id key

    def sort_key(key)
      sort_key = case key
                 when :date
                   [placed_date.strftime('%FT%T'), title, author, call_number]
                 when :title
                   [title, author, call_number]
                 when :default
                   [date_sort_key, title, author, call_number]
                 end
      sort_key.join('---')
    end

    def date_sort_key
      (expiration_date || Folio::Request::END_OF_DAYS).strftime('%FT%T')
    end

    def title
      scan_type? ? @illiad_result['PhotoJournalTitle'] : @illiad_result['LoanTitle']
    end

    def call_number
      @illiad_result['CallNumber']
    end

    def author
      scan_type? ? @illiad_result['PhotoArticleAuthor'] : @illiad_result['LoanAuthor']
    end

    def placed_date
      Time.zone.parse(@illiad_result['CreationDate'])
    end

    def library_name
      'Interlibrary Loan'
    end

    def expiration_date
      based_on_placed = placed_date + 2.months
      # In some cases, even if the request is a hold/recall and not a scan,
      # the 'NotWantedAfter' field may be blank. In that case, we will just
      # use the date that is 2 months after the transaction creation date
      scan_type? ? based_on_placed : (user_supplied_expiration_date || based_on_placed)
    end

    def user_supplied_expiration_date
      return nil if @illiad_result['NotWantedAfter'].blank?

      parse_expiration_date(@illiad_result['NotWantedAfter'])
    end

    def parse_expiration_date(illiad_date)
      # Some dates will be in mm/dd/yyyy or m/d/yyyy format, and Time.zone.parse will throw an error
      date_regex = %r{\d{1,2}/\d{1,2}/\d{4}}
      date_to_parse = illiad_date.match?(date_regex) ? Date.strptime(illiad_date, '%m/%d/%Y').to_s : illiad_date
      # We still want to return a date that provides a time portion/is consistent with the other results
      Time.zone.parse(date_to_parse)
    rescue ArgumentError => e
      Honeybadger.notify(e, error_message: "Parsing #{illiad_date} for ILLIAD request expiration date returns #{e}")
      nil
    end

    def fill_by_date; end

    def ready_for_pickup?
      ready_for_pickup_status = ['Media Microtext Checkout to Customer',
                                 'Special Collections Checked Out to Customer',
                                 'Library Use Only held at Green Circ Desk',
                                 'Customer Notified via E-Mail',
                                 'Delivered to Web']
      ready_for_pickup_status.include?(@illiad_result['TransactionStatus'])
    end

    def from_ill?
      true
    end

    def service_point_name
      Folio::Types.libraries.find_by(code: library_code)&.name
    end

    def waitlist_position; end

    def to_partial_path
      'requests/request'
    end

    def manage_request_link
      "https://sulils.stanford.edu/illiad.dll?Action=10&Form=72&Value=#{key}"
    end

    private

    def library_code
      @illiad_result['ItemInfo4']
    end
  end
end
