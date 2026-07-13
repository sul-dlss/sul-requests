# frozen_string_literal: true

# FOLIO requests
class IllRequestsController < ApplicationController
  include FolioController

  before_action :authenticate_user!

  before_action :load_requests

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

  def create # rubocop:disable Metrics/MethodLength,Metrics/AbcSize
    authorize! :create, Illiad::Request

    illiad_create_params = create_params.except(:title, :author, :NotWantedAfter, :AcceptAlternateEdition).to_h.merge(
      ProcessType: 'Borrowing',
      WebRequestForm: 'LoanRequest',
      RequestType: 'Loan',
      LoanTitle: create_params[:title],
      LoanAuthor: create_params[:author],
      Username: current_patron.username,
      UserInfo1: current_patron.blocked? ? 'Blocked' : nil,
      UserInfo5: current_patron.barcode,
      AcceptAlternateEdition: ActiveModel::Type::Boolean.new.cast(create_params[:AcceptAlternateEdition]) ? 'E Version Acceptable' : '',
      NotWantedAfter: not_wanted_after_param.strftime('%Y-%m-%d')
    ).compact_blank

    IlliadClient.new.create(illiad_create_params)

    redirect_to root_path, notice: 'Your request has been submitted to Interlibrary Loan.'
  end

  def destroy
    load_request
    authorize! :destroy, @request
    @response = IlliadClient.new.update_request_route(transaction_number: @request.id, status: Settings.illiad.cancelled_by_user)
    respond_to do |format|
      format.html { redirect_to unified_requests_path, notice: 'Request cancelled successfully' }
      format.turbo_stream
    end
  end

  private

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
    return 1.year.from_now if create_params[:NotWantedAfter].blank?

    Date.parse(create_params[:NotWantedAfter])
  rescue StandardError
    1.year.from_now
  end

  def create_params
    illiad_params = %w[
      CitedIn ISSN ESPNumber ItemInfo2
      LoanPublisher LoanPlace LoanDate LoanEdition AcceptAlternateEdition
      Notes NotWantedAfter
    ]
    params.require(:illiad_request).permit(:title, :author, *illiad_params)
  end
end
