# frozen_string_literal: true

# Client for the Illiad API
class IlliadClient
  # Accepts a Faraday::Response or plain message to report on Illiad API errors
  class ApiError < StandardError
    attr_reader :response

    def initialize(response_or_message = nil)
      if response_or_message.is_a?(Faraday::Response)
        @response = response_or_message
        super("Illiad API #{response.env.method.to_s.upcase} #{response.env.url.path} failed: #{response.status}")
      else
        super
      end
    end

    def to_honeybadger_context
      return {} unless response

      env = response.env
      {
        status: response.status,
        method: env.method.to_s.upcase,
        url: env.url.to_s,
        request_body: env.request_body,
        response_body: response.body
      }
    end
  end

  def initialize(url: Settings.sul_illiad, api_key: Settings.illiad_api_key)
    @base_url = url
    @api_key = api_key
  end

  def create(request_data)
    response = connection.post('ILLiadWebPlatform/Transaction/', request_data.as_json.compact, content_type: 'application/json')

    handle_response(response, as_class: Illiad::Request)
  end

  UNSET = Data.define do
    def method_missing(*, **, &)
      self # always return the unset object itself so it chains without error
    end

    def respond_to_missing?(*)
      false
    end
  end.new

  RequestData = Data.define(:accept_alternate_edition, :call_number, :cited_in, :esp_number, :ill_number, :issn,
                            :item_info1, :item_info2, :item_info3, :item_info4, :item_info5, :item_number,
                            :loan_author, :loan_date, :loan_edition, :loan_place, :loan_publisher, :loan_title,
                            :location, :not_wanted_after,
                            :photo_article_author, :photo_article_title, :photo_journal_inclusive_pages,
                            :photo_journal_volume,
                            :photo_journal_issue, :photo_journal_month, :photo_journal_year, :photo_journal_title,
                            :process_type, :reference_number, :request_type, :spec_ins,
                            :username, :user_info1, :user_info2, :user_info3, :user_info4, :user_info5, :web_request_form) do
    def as_json # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      {
        AcceptAlternateEdition: ActiveModel::Type::Boolean.new.cast(accept_alternate_edition),
        CallNumber: call_number,
        CitedIn: cited_in,
        ESPNumber: esp_number,
        ILLNumber: ill_number,
        ISSN: issn,
        ItemInfo1: item_info1,
        ItemInfo2: item_info2,
        ItemInfo3: item_info3,
        ItemInfo4: item_info4,
        ItemInfo5: item_info5,
        ItemNumber: item_number,
        LoanAuthor: loan_author,
        LoanDate: loan_date,
        LoanEdition: loan_edition,
        LoanPlace: loan_place,
        LoanPublisher: loan_publisher,
        LoanTitle: loan_title,
        Location: location,
        NotWantedAfter: not_wanted_after.strftime('%Y-%m-%d'),
        PhotoArticleAuthor: photo_article_author,
        PhotoArticleTitle: photo_article_title,
        PhotoJournalInclusivePages: photo_journal_inclusive_pages,
        PhotoJournalIssue: photo_journal_issue,
        PhotoJournalMonth: photo_journal_month,
        PhotoJournalVolume: photo_journal_volume,
        PhotoJournalTitle: photo_journal_title,
        PhotoJournalYear: photo_journal_year,
        ProcessType: process_type,
        ReferenceNumber: reference_number,
        RequestType: request_type,
        SpecIns: spec_ins,
        Username: username,
        UserInfo1: user_info1,
        UserInfo2: user_info2,
        UserInfo3: user_info3,
        UserInfo4: user_info4,
        UserInfo5: user_info5,
        WebRequestForm: web_request_form
      }.reject { |_k, v| v == UNSET }
    end

    def self.with_defaults
      new(**members.index_with(UNSET), accept_alternate_edition: false, process_type: 'Borrowing', not_wanted_after: 1.year.from_now)
    end
  end

  def user_transactions(user_id)
    response = connection.get("ILLiadWebPlatform/Transaction/UserRequests/#{user_id}")

    handle_response(response, as_class: Illiad::Request, not_found: [])
  end

  def create_transaction_note(transaction_number:, note:)
    connection.post("ILLiadWebPlatform/Transaction/#{transaction_number}/Note", { Note: note, NoteType: 'Staff' },
                    content_type: 'application/json')

    handle_response(response)
  end

  def update_request_route(transaction_number:, status:)
    response = connection.put("ILLiadWebPlatform/transaction/#{transaction_number}/route", { Status: status },
                              content_type: 'application/json')

    handle_response(response, as_class: Illiad::Request)
  end

  private

  def connection
    Faraday.new(url: @base_url) do |req|
      req.request :json
      req.response :json

      default_headers.each do |k, v|
        req.headers[k] = v
      end

      req.adapter Faraday.default_adapter
    end
  end

  def default_headers
    { ApiKey: @api_key, Accept: 'application/json; version=1' }
  end

  def handle_response(faraday_response, as_class: nil, not_found: nil) # rubocop:disable Metrics/MethodLength
    if faraday_response.success?
      body = faraday_response.body
      return yield body unless as_class

      if body.is_a?(Array)
        Array.wrap(body).map { |data| as_class.from_dynamic(data) }
      else
        as_class.from_dynamic(body)
      end
    elsif faraday_response.status == 404
      not_found
    else
      raise ApiError, faraday_response
    end
  end
end
