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

  def create # rubocop:disable Metrics/AbcSize
    authorize! :create, Illiad::Request

    request = illiad_client.create(IlliadClient::RequestData.with_defaults.with(**request_data_params).as_json)
    illiad_client.create_transaction_note(transaction_number: request.key, note: create_params[:note]) if create_params[:note].present?

    redirect_to root_path, notice: 'Your request has been submitted to Interlibrary Loan.'
  end

  def destroy
    load_request
    authorize! :destroy, @request
    @response = illiad_client.update_request_route(transaction_number: @request.id, status: Settings.illiad.cancelled_by_user)
    respond_to do |format|
      format.html { redirect_to unified_requests_path, notice: 'Request cancelled successfully' }
      format.turbo_stream
    end
  end

  private

  def request_data_params
    static_params = { patron: current_patron }
    if create_params[:accept_alternate_edition].present?
      static_params['accept_alternate_edition'] = ActiveModel::Type::Boolean.new.cast(create_params[:accept_alternate_edition])
    end
    create_params.except(:note).to_h.compact_blank.merge(static_params)
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
    return 1.year.from_now if create_params[:NotWantedAfter].blank?

    Date.parse(create_params[:NotWantedAfter])
  rescue StandardError
    1.year.from_now
  end

  def create_params
    params.require(:illiad_request).permit(:title, :author, :item_url, :isbn, :oclcn, :note,
                                           :volume, :publisher, :published_location, :published_date,
                                           :edition, :accept_alternate_edition, :needed_date, :request_type,
                                           :issue, :issue_month, :issue_year, :destination_library_code,
                                           :scan_title, :scan_authors, :scan_page_range)
  end
end
