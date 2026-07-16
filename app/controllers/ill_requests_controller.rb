# frozen_string_literal: true

# FOLIO requests
class IllRequestsController < ApplicationController
  include FolioController

  before_action :authenticate_user!

  before_action :load_requests
  before_action :load_request, only: [:destroy, :edit, :update]
  before_action :set_variant, only: [:edit]

  # Renders user requests from ILL sources
  #
  # GET /ill_requests
  # GET /ill_requests.json
  def index
    render 'async' and return if params[:async]
  end

  def new
    authorize! :create, Illiad::Request
  end

  def edit; end

  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    authorize! :create, Illiad::Request

    scan = create_params[:photo_article_title].present?
    title_param = if scan
                    { photo_journal_title: create_params[:title] }
                  else
                    { loan_title: create_params[:title] }
                  end

    illiad_create_params = IlliadClient::RequestData.with_defaults.with_patron(current_patron).with(
      process_type: scan ? 'DocDel' : 'Borrowing',
      web_request_form: 'LoanRequest',
      request_type: scan ? IlliadClient::UNSET : 'Loan',
      accept_alternate_edition: create_params[:accept_alternate_edition] || IlliadClient::UNSET,
      not_wanted_after: not_wanted_after_param || IlliadClient::UNSET,
      **title_param,
      **create_params.except(:title, :not_wanted_after, :accept_alternate_edition, :note).to_h.compact_blank
    )

    request = illiad_client.create(illiad_create_params)
    illiad_client.create_transaction_note(transaction_number: request.key, note: create_params[:note]) if create_params[:note].present?

    redirect_to root_path, notice: 'Your request has been submitted to Interlibrary Loan.'
  end

  def update
    authorize! :update, @request
    IlbMailer.updated_ilb_notification(current_patron, @request, updated_fields).deliver_now unless updated_fields.empty?
    respond_to do |format|
      format.html { redirect_to unified_requests_path, notice: 'Request updated successfully' }
      format.turbo_stream
    end
  end

  def destroy
    authorize! :destroy, @request
    @response = illiad_client.update_request_route(transaction_number: @request.id, status: Settings.illiad.cancelled_by_user)
    respond_to do |format|
      format.html { redirect_to unified_requests_path, notice: 'Request cancelled successfully' }
      format.turbo_stream
    end
  end

  private

  def updated_fields
    update_params.to_h.compact_blank.filter { |param, value| @request.public_send(param)&.to_s&.strip != value.strip }
  end

  def illiad_client
    @illiad_client ||= IlliadClient.new
  end

  def current_patron
    current_user.patron
  end

  def load_requests
    @requests = patron_or_group.illiad_requests.sort_by { |request| request.sort_key(:date) }
  end

  def load_request
    @request = @requests.find { |r| r.key == params['id'] }
    raise RequestException, 'Error' unless @request
  end

  def not_wanted_after_param
    return if create_params[:not_wanted_after].blank?

    Date.parse(create_params[:not_wanted_after])
  rescue StandardError
    nil
  end

  def update_params
    params.require(:illiad_request).permit(:not_wanted_after, :item_info4, :photo_article_title, :photo_article_author,
                                           :photo_journal_inclusive_pages)
  end

  def create_params
    illiad_params = %w[
      loan_author
      cited_in issn esp_number item_info2
      loan_publisher loan_place loan_date loan_edition accept_alternate_edition
      photo_journal_issue photo_journal_month photo_journal_year
      item_info4 not_wanted_after note
      photo_article_title photo_article_author photo_journal_inclusive_pages
    ]
    params.require(:illiad_request).permit(:title, *illiad_params)
  end
end
