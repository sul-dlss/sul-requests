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
  def index; end

  private

  def load_requests
    @requests = (patron_or_group.illiad_requests + patron_or_group.borrow_direct_requests).sort_by { |request| request.sort_key(:date) }
  end

  def load_request
    @request = @requests.find { |r| r.key == params['id'] }
    raise RequestException, 'Error' unless @request
  end
end
